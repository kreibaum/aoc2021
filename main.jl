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