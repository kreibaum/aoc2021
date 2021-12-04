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

function bingo(input)
    call_order = parse.(Int, split(popfirst!(input), ","))

    boards = []
    while length(input) > 0
        board = popBingoBoard!(input)
        if length(board) > 0
            push!(boards, board)
        end
    end

    best_duration = length(call_order) + 1
    score_of_best = 0
    for board in boards
        duration, drawn = @show bingo_duration(call_order, board)
        if duration < best_duration
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

function has_line(drawn::Vector, call_index)
    # Vertical
    col = (call_index - 1) % 5 + 1
    if all(drawn[[col, col + 5, col + 10, col + 15, col + 20]] .== 1)
        return true
    end
    # Horizontal
    row = call_index - col + 1
    if all(drawn[[row, row + 1, row + 2, row + 3, row + 4]] .== 1)
        return true
    end
    # # Diagonal /
    # if all(drawn[[21, 17, 13, 9, 5]] .== 1)
    #     @show 
    #     return true
    # end
    # # Diagonal \
    # if all(drawn[[1, 7, 13, 19, 25]] .== 1)
    #     return true
    # end
    return false
end

"""Pop 5 lines and return a bingo board. Resistant agains empty lines."""
function popBingoBoard!(input)::Vector{Int}
    result = []
    while length(result) < 25
        if length(input) == 0
            if length(result) > 0
                throw("Incomplete Bingo: $result")
            else
                break
            end
        end
        line = parse.(Int, split(popfirst!(input)))
        append!(result, line)
    end
    result
end

@show bingo(day04_test)
@show bingo(day04_input)