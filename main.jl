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

function swim(instr::Vector{String})
    x = 0
    y = 0
    for i in instr
        m = match(r"forward ([0-9]+)", i)
        if m != nothing
            x = x + parse(Int, m[1])
        end
        m = match(r"down ([0-9]+)", i)
        if m != nothing
            y = y + parse(Int, m[1])
        end
        m = match(r"up ([0-9]+)", i)
        if m != nothing
            y = y - parse(Int, m[1])
        end
    end
    x * y
end

@assert 150 == @show swim(day02_test)
@assert 2019945 == @show swim(day02_input)


function swim2(instr::Vector{String})
    aim = 0
    x = 0
    y = 0
    for i in instr
        m = match(r"forward ([0-9]+)", i)
        if m != nothing
            x = x + parse(Int, m[1])
            y = y + aim * parse(Int, m[1])
        end
        m = match(r"down ([0-9]+)", i)
        if m != nothing
            aim = aim + parse(Int, m[1])
        end
        m = match(r"up ([0-9]+)", i)
        if m != nothing
            aim = aim - parse(Int, m[1])
        end
    end
    x * y
end

@assert 900 == @show swim2(day02_test)
@assert 1599311480 == @show swim2(day02_input)