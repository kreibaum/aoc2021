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

tuple_product(t::Tuple{Number,Number}) = t[1] * t[2]

"""Given a vector of swim instructions, this method returns the final position.
It is however using the 'part a incorrect assumption' for the determination."""
function legacy_swim(instructions::Vector{String})::Tuple{Int,Int}
    x = 0
    y = 0
    for instruction in instructions
        dir, t = parse_swim_instruction(instruction)
        if dir == "forward"
            x = x + t
        elseif dir == "down"
            y = y + t
        elseif dir == "up"
            y = y - t
        else
            throw("direction $dir not recognized")
        end
    end
    (x, y)
end

@assert 150 == @show tuple_product(legacy_swim(day02_test))
@assert 2019945 == @show tuple_product(legacy_swim(day02_input))

"""Given a vector of swim instructions, this method returns the final position."""
function swim(instructions::Vector{String})::Tuple{Int,Int}
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
        end
    end
    (x, y)
end

@assert 900 == @show tuple_product(swim(day02_test))
@assert 1599311480 == @show tuple_product(swim(day02_input))