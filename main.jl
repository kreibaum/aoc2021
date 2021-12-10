## Advent of Code 2021 ##
#########################

## Day 01: Sonar Sweep ##
#########################

day1_test = [199, 200, 208, 210, 200, 207, 240, 269, 260, 263]
day1_input = parse.(Int, readlines(open("input-01")))

"""Given a Vector of Int depth values, this counts how often it decreases when
going from position i to i+step_size."""
function depth_count(depth_array::Vector{Int}, step_size::Int = 1)
    counter = 0
    for i = 1:(length(depth_array)-step_size)
        if depth_array[i] < depth_array[i+step_size]
            counter = counter + 1
        end
    end
    counter
end

@assert 0 == depth_count(day1_test, 100)
@assert 7 == @show depth_count(day1_test)
@assert 1532 == @show depth_count(day1_input)

@assert 5 == @show depth_count(day1_test, 3)
@assert 1571 == @show depth_count(day1_input, 3)


## Day 02: Dive! ##
###################

day02_test = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]
day02_input = readlines(open("input-02"))

"""Tries to parse the instruction as "direction distance" code and crashes if
that is not possible."""
function parse_swim_instruction(instruction::String)
    m = match(r"^(forward|down|up) ([0-9]+)$", instruction)
    (m[1], parse(Int, m[2]))
end

"""Given a vector of swim instructions, this method returns the final position and aim value."""
function swim(instructions::Vector{String})::Tuple{Int,Int,Int}
    aim = 0
    x = 0
    y = 0
    for instruction in instructions
        dir, t = parse_swim_instruction(instruction)
        if dir == "forward"
            x = x + t
            y = y + aim * t
        elseif dir == "down"
            aim = aim + t
        elseif dir == "up"
            aim = aim - t
        else
            throw("Direction $dir not recognized")
        end
    end
    (x, y, aim)
end

legacy_position_product(t::Tuple) = t[1] * t[3] # x * aim
position_product(t::Tuple) = t[1] * t[2] # x * y

@assert 150 == @show legacy_position_product(swim(day02_test))
@assert 2019945 == @show legacy_position_product(swim(day02_input))
@assert 900 == @show position_product(swim(day02_test))
@assert 1599311480 == @show position_product(swim(day02_input))


## Day 03: Binary Diagnostic ##
###############################

day03_test = ["00100", "11110", "10110", "10111", "10101", "01111", "00111", "11100", "10000", "11001", "00010", "01010"]
day03_input = readlines(open("input-03"))

"""Given a vector of bit strings "00110", this returns the most common character
at the given index. If they occur the same amount, returns 1."""
function most_common_digit(diagnostics::Vector{String}, index::Int)::Int
    ones_count = 0
    zeros_count = 0
    for diagnostic in diagnostics
        char = diagnostic[index]
        if char == '1'
            ones_count += 1
        elseif char == '0'
            zeros_count += 1
        else
            throw("Illegal character $(diagnostic[i]) in diagnostic code")
        end
    end
    ones_count >= zeros_count ? 1 : 0
end

@assert most_common_digit(day03_test, 1) == 1
@assert most_common_digit(day03_test, 2) == 0
@assert most_common_digit(day03_test, 3) == 1
@assert most_common_digit(day03_test, 4) == 1
@assert most_common_digit(day03_test, 5) == 0

"""Turns [1,0,0,1,0] into 18."""
function parse_binary(vec::Vector)::Int
    result = 0
    for v in vec
        result = 2 * result + v
    end
    result
end

@assert parse_binary([]) == 0
@assert parse_binary([1, 0, 0, 1, 0]) == 18

function power_consumption(diagnostics::Vector{String})
    gamma = map(i -> most_common_digit(diagnostics, i), 1:length(diagnostics[1]))
    epsilon = map(x -> 1 - x, gamma) # invert digits
    parse_binary(gamma) * parse_binary(epsilon)
end

@assert 198 == @show power_consumption(day03_test)
@assert 3959450 == @show power_consumption(day03_input) # 1565 is not the right answer

function find_rating(diagnostics::Vector{String}, invert = false, i = 1)::Int
    if length(diagnostics) > 1
        most_common = most_common_digit(diagnostics, i)
        most_common = invert ? 1 - most_common : most_common
        filtered_list = filter(d -> parse(Int, d[i]) == most_common, diagnostics)
        find_rating(filtered_list, invert, i + 1)
    elseif length(diagnostics) == 1
        parse(Int, diagnostics[1], base = 2)
    else
        throw("No unique result found")
    end
end

@assert 23 == find_rating(day03_test) # oxygen generator
@assert 10 == find_rating(day03_test, true) # co2 scrubber

life_support_rating(diagnostics) = find_rating(diagnostics) * find_rating(diagnostics, true)

@assert 230 == @show life_support_rating(day03_test)
@assert 7440311 == @show life_support_rating(day03_input)


## Day 04: Giant Squid ##
#########################


day04_test = readlines(open("test-04"))
day04_input = readlines(open("input-04"))

# A board is a Vector with 25 entries.
# A draw state is a Boolean Vector with 25 entries

function bingo(input; find_first = true)
    input = copy(input)
    call_order = parse.(Int, split(popfirst!(input), ","))

    boards = []
    while length(input) > 0
        board = popBingoBoard!(input)
        if length(board) > 0
            push!(boards, board)
        end
    end

    best_duration = find_first ? length(call_order) + 1 : 0
    score_of_best = 0
    for board in boards
        duration, drawn = bingo_duration(call_order, board)
        is_better = (find_first && duration < best_duration) || (!find_first && duration > best_duration)
        if is_better
            best_duration = duration
            score_of_best = 0
            for i = 1:25
                if drawn[i] == 0
                    score_of_best += board[i]
                end
            end
        end
    end
    score_of_best * call_order[best_duration]
end

"""Given a Bingo and a call order, this method marks one call at a time and 
checks for a strait line. If there is a line, the marked pattern is returned
alongside the duration it took to get there."""
function bingo_duration(call_order::Vector{Int}, board::Vector{Int})::Tuple{Int,Vector{Int}}
    drawn = zeros(Int, 25)
    call_count = 0
    for call in call_order
        call_count += 1
        call_index = findfirst(x -> x == call, board)
        if call_index !== nothing
            drawn[call_index] = 1
            if has_line(drawn, call_index)
                break
            end
        end
    end
    call_count, drawn
end

"""Checks if there is a horizontal or vertical line through the call index."""
function has_line(drawn::Vector, call_index)
    @assert length(drawn) == 25 "Malformed drawn pattern $drawn."
    @assert 1 <= call_index <= 25 "Call index $call_index out of bounds."
    col = (call_index - 1) % 5 + 1
    row = call_index - col + 1
    if all(drawn[[col, col + 5, col + 10, col + 15, col + 20]] .== 1)
        true # Vertical
    elseif all(drawn[[row, row + 1, row + 2, row + 3, row + 4]] .== 1)
        true # Horizontal
    else
        false
    end
end

"""Pop 25 numbers and return a bingo board. Resistant against empty lines.

Returns `nothing` when there are no Bingos left.
"""
function popBingoBoard!(input)::Union{Vector{Int},Nothing}
    result = []
    while length(result) < 25
        if length(input) == 0
            if length(result) == 0
                return nothing
            else
                throw("Incomplete Bingo: $result")
            end
        end
        line = parse.(Int, split(popfirst!(input)))
        append!(result, line)
    end
    if length(result) == 25
        result
    else
        throw("Malformed Bingo: $result")
    end
end

@assert 4512 == @show bingo(day04_test)
@assert 11536 == @show bingo(day04_input)

@assert 1924 == @show bingo(day04_test; find_first = false)
@assert 1284 == @show bingo(day04_input; find_first = false)


## Day 05: Hydrothermal Venture ##
##################################

day05_test = readlines(open("test-05"))
day05_input = readlines(open("input-05"))

function vent_intersections(data; skip_diagonals = false)
    diagramm = Dict()
    for d in data
        m = match(r"([0-9]+),([0-9]+) -> ([0-9]+),([0-9]+)", d)
        if m[1] == m[3]
            x = parse(Int, m[1])
            for y in r(parse(Int, m[2]), parse(Int, m[4]))
                v = get(diagramm, (x, y), 0)
                diagramm[(x, y)] = v + 1
            end
        elseif m[2] == m[4]
            y = parse(Int, m[2])
            for x in r(parse(Int, m[1]), parse(Int, m[3]))
                v = get(diagramm, (x, y), 0)
                diagramm[(x, y)] = v + 1
            end
        elseif skip_diagonals
            continue
        else
            x1 = parse(Int, m[1])
            y1 = parse(Int, m[2])
            x2 = parse(Int, m[3])
            y2 = parse(Int, m[4])
            dx = x1 < x2 ? 1 : -1
            dy = y1 < y2 ? 1 : -1
            for i = 0:(abs(x2 - x1))
                x = x1 + i * dx
                y = y1 + i * dy
                v = get(diagramm, (x, y), 0)
                diagramm[(x, y)] = v + 1
            end
        end
    end
    intersects = 0
    for (_key, value) in diagramm
        if value > 1
            intersects += 1
        end
    end
    intersects
end

r(a, b) = a < b ? (a:b) : (b:a)

@assert 5 == @show vent_intersections(day05_test; skip_diagonals = true)
@assert 6007 == @show vent_intersections(day05_input; skip_diagonals = true)

@assert 12 == @show vent_intersections(day05_test)
@assert 19349 == @show vent_intersections(day05_input)


## Day 06: Lanternfish ##
#########################

day06_test = [3, 4, 3, 1, 2]
day06_input = parse.(Int, split(read(open("input-06"), String), ","))

function group_fish(fish_list::Vector{Int})::Dict{Int,Int}
    groups = Dict{Int,Int}()
    for fish in fish_list
        groups[fish] = get(groups, fish, 0) + 1
    end
    groups
end

@assert group_fish(day06_test) == Dict(1 => 1, 2 => 1, 3 => 2, 4 => 1)

function pass_time(fish_dict::Dict{Int,Int})::Dict{Int,Int}
    groups = Dict{Int,Int}()
    for (time, count) in fish_dict
        if time == 0
            # Special case where we spawn offspring
            groups[8] = get(groups, 8, 0) + count
            groups[6] = get(groups, 6, 0) + count
        else
            groups[time-1] = get(groups, time - 1, 0) + count
        end
    end
    groups
end

function pass_time(fish_dict::Dict{Int,Int}, repeats::Int)::Dict{Int,Int}
    @assert repeats >= 0 "Passed in a negative repeat count $repeats which is invalid."
    if repeats == 0
        fish_dict
    else
        pass_time(pass_time(fish_dict), repeats - 1)
    end
end

count_fish(fish_dict) = sum(values(fish_dict))

@assert pass_time(group_fish(day06_test)) == Dict(0 => 1, 1 => 1, 2 => 2, 3 => 1)
@assert pass_time(group_fish(day06_test), 2) == Dict(6 => 1, 8 => 1, 0 => 1, 1 => 2, 2 => 1)

@assert 5934 == @show count_fish(pass_time(group_fish(day06_test), 80))
@assert 362639 == @show count_fish(pass_time(group_fish(day06_input), 80))

@assert 26984457539 == @show count_fish(pass_time(group_fish(day06_test), 256))
@assert 1639854996917 == @show count_fish(pass_time(group_fish(day06_input), 256))


## Day 07: The Treachery of Whales ##
#####################################

day07_test = [16, 1, 2, 0, 4, 2, 7, 1, 2, 14]
day07_input = parse.(Int, split(read(open("input-07"), String), ","))

using Statistics # median

function crab_distance(crabs::Vector{Int})
    m = Int(floor(Statistics.median(crabs)))
    sum(abs.(crabs .- m))
end

@assert 37 == @show crab_distance(day07_test)
@assert 356992 == @show crab_distance(day07_input)

function crab_distance_2(crabs::Vector{Int})
    m = mean(crabs)
    fuel1 = sum(square_fuel.(abs.(crabs .- Int(floor(m)))))
    fuel2 = sum(square_fuel.(abs.(crabs .- Int(ceil(m)))))
    min(fuel1, fuel2)
end

square_fuel(d) = Int(d * (d + 1) / 2)

@assert square_fuel(0) == 0
@assert square_fuel(1) == 1
@assert square_fuel(2) == 3
@assert square_fuel(3) == 6

@assert 168 == @show crab_distance_2(day07_test)
@assert 101268110 == @show crab_distance_2(day07_input)


## Day 08: Seven Segment Search ##
##################################

day08_test = readlines(open("test-08"))
day08_input = readlines(open("input-08"))

function easy_7_digit_numbers(data)
    count = 0
    for d in data
        output = split(d, "|")[2]
        out_groups = split(output)
        for group in out_groups
            if length(group) in [2, 3, 4, 7]
                count += 1
            end
        end
    end
    count
end

@assert 26 == @show easy_7_digit_numbers(day08_test)
@assert 344 == @show easy_7_digit_numbers(day08_input)

# Part 2 seems really hard.

#  4444
# 5    1
# 5    1
#  6666
# 7    2
# 7    2
#  3333

segments_to_digit = Dict(
    Set([1, 2, 3, 4, 5, 7]) => 0, Set([1, 2]) => 1, Set([4, 1, 6, 7, 3]) => 2,
    Set([4, 1, 6, 2, 3]) => 3, Set([1, 2, 5, 6]) => 4, Set([4, 5, 6, 2, 3]) => 5,
    Set([2, 3, 4, 5, 6, 7]) => 6, Set([4, 1, 2]) => 7,
    Set([1, 2, 3, 4, 5, 6, 7]) => 8, Set([1, 2, 3, 4, 5, 6]) => 9)

# Seems like we have all 10 numbers in a random order each time. So we should be
# able to solve it the same way every time.

function solve_7_digit_puzzle(data)
    input = split(data, "|")[1]
    in_group = Set.(split(input))
    # Solve
    eight = grab!(in_group, 7)
    one = grab!(in_group, 2)
    seven = grab!(in_group, 3)
    l4 = first(setdiff(seven, one)) # Seven minus one leaves the top letter.
    six = grab_if!(in_group, x -> length(x) == 6 && length(intersect(one, x)) == 1)
    l1 = first(setdiff(one, six))
    l2 = first(intersect(one, six))
    four = grab!(in_group, 4)
    zero = grab_if!(in_group, x -> length(x) == 6 && length(intersect(four, x)) == 3)
    nine = grab_if!(in_group, x -> length(x) == 6 && length(intersect(four, x)) == 4)
    l6 = first(setdiff(eight, zero))
    l7 = first(setdiff(eight, nine))
    l5 = first(setdiff(four, Set([l1, l2, l6])))
    l3 = first(setdiff(eight, Set([l1, l2, l4, l5, l6, l7])))

    mapping = Dict(l1 => 1, l2 => 2, l3 => 3, l4 => 4, l5 => 5, l6 => 6, l7 => 7)

    total = 0

    output = split(data, "|")[2]
    out_groups = Set.(split(output))
    for group in out_groups
        g = Set([mapping[c] for c in group])
        total = 10 * total + segments_to_digit[g]
    end
    total
end

grab!(vec, l) = grab_if!(vec, x -> length(x) == l)
grab_if!(vec, test) = popat!(vec, findfirst(test, vec))

@assert 61229 == @show sum(solve_7_digit_puzzle.(day08_test))
@assert 1048410 == @show sum(solve_7_digit_puzzle.(day08_input))


## Day 09: Smoke Basin ##
#########################

day09_test = ["2199943210",
    "3987894921",
    "9856789892",
    "8767896789",
    "9899965678"]
day09_input = readlines(open("input-09"))

function height_map(input::Vector{String})::Array{Int,2}
    h = length(input)
    w = length(input[1])
    h_map = zeros(Int, (w, h))

    for y = 1:h, x = 1:w
        h_map[x, y] = parse(Int, input[y][x])
    end
    h_map
end

function get_basin_mins(h_map::Array{Int,2})::Tuple{Vector{Tuple{Int,Int}},Int}
    w, h = size(h_map)
    mins = []
    score = 0
    for x = 1:w, y = 1:h
        v = h_map[x, y]
        if x >= 2 && h_map[x-1, y] <= v
            continue
        elseif x < w && h_map[x+1, y] <= v
            continue
        elseif y >= 2 && h_map[x, y-1] <= v
            continue
        elseif y < h && h_map[x, y+1] <= v
            continue
        end
        push!(mins, (x, y))
        score += 1 + v
    end
    (mins, score)
end

@assert 15 == @show get_basin_mins(height_map(day09_test))[2]
@assert 439 == @show get_basin_mins(height_map(day09_input))[2]

# Now for part 2 I need to find connected regions that are divided by 9s.
# Sounds like I need some kind of flood-fill algorithm.

function basins(h_map::Array{Int,2})::Int
    mins = get_basin_mins(h_map)[1]
    sizes = []
    for (x, y) in mins
        b_size = flood_fill(h_map, x, y)
        push!(sizes, b_size)
    end
    prod(sort(sizes)[end-2:end])
end

function flood_fill(h_map::Array{Int,2}, x::Int, y::Int)::Int
    is_inside = zeros(Bool, size(h_map))
    flood_fill!(is_inside, h_map, x, y)
    sum(is_inside)
end

function flood_fill!(is_inside::Array{Bool,2}, h_map::Array{Int,2}, x::Int, y::Int)
    is_inside[x, y] = true
    w, h = size(h_map)
    if x >= 2 && h_map[x-1, y] != 9 && !is_inside[x-1, y]
        flood_fill!(is_inside, h_map, x - 1, y)
    end
    if x < w && h_map[x+1, y] != 9 && !is_inside[x+1, y]
        flood_fill!(is_inside, h_map, x + 1, y)
    end
    if y >= 2 && h_map[x, y-1] != 9 && !is_inside[x, y-1]
        flood_fill!(is_inside, h_map, x, y - 1)
    end
    if y < h && h_map[x, y+1] != 9 && !is_inside[x, y+1]
        flood_fill!(is_inside, h_map, x, y + 1)
    end
end

@assert 1134 == @show basins(height_map(day09_test))
@assert 900900 == @show basins(height_map(day09_input))


## Day 10: Syntax Scoring ##
############################

day10_test = readlines(open("test-10"))
day10_input = readlines(open("input-10"))

function corrupted(line)
    stack = []
    for char in line
        if char in "([<{"
            push!(stack, char)
            continue
        end
        if length(stack) == 0
            return char
        end
        opening = pop!(stack)
        if char == ')' && opening != '('
            return char
        elseif char == ']' && opening != '['
            return char
        elseif char == '>' && opening != '<'
            return char
        elseif char == '}' && opening != '{'
            return char
        end
    end
    return nothing
end

function corruption_score(line)
    symbol = corrupted(line)
    if symbol === nothing
        0
    elseif symbol == ')'
        3
    elseif symbol == ']'
        57
    elseif symbol == '}'
        1197
    elseif symbol == '>'
        25137
    else
        throw("bad symbol $symbol")
    end
end

@assert 26397 == @show sum(corruption_score.(day10_test))
@assert 315693 == @show sum(corruption_score.(day10_input))

# Part two

function closing_stack(line)
    stack = []
    for char in line
        if char in "([<{"
            push!(stack, char)
            continue
        end
        if length(stack) == 0
            throw("corrupted")
        end
        opening = pop!(stack)
        if char == ')' && opening != '('
            throw("corrupted")
        elseif char == ']' && opening != '['
            throw("corrupted")
        elseif char == '>' && opening != '<'
            throw("corrupted")
        elseif char == '}' && opening != '{'
            throw("corrupted")
        end
    end
    stack
end

function closing_score(line)
    if corruption_score(line) > 0
        0
    else
        stack = closing_stack(line)
        v = 0
        for c in reverse(stack)
            v = 5 * v
            if c == '('
                v += 1
            elseif c == '['
                v += 2
            elseif c == '{'
                v += 3
            elseif c == '<'
                v += 4
            else
                throw("not a bracket $c")
            end
        end
        v
    end
end

function middle_score(lines::Vector{String})::Int
    scores = filter(x -> x > 0, closing_score.(lines))
    sort(scores)[Int((1 + end) / 2)]
end

@assert 288957 == @show middle_score(day10_test)
@assert 1870887234 == @show middle_score(day10_input)