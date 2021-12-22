## Day 22: Reactor Reboot ##
############################

struct Instr
    is_on::Bool
    x1::Int
    x2::Int
    y1::Int
    y2::Int
    z1::Int
    z2::Int
end


function parse_line(line::String)::Instr
    m = match(r"(on|off) x=(-?[0-9]+)..(-?[0-9]+),y=(-?[0-9]+)..(-?[0-9]+),z=(-?[0-9]+)..(-?[0-9]+)", line)
    Instr(m[1] == "on", parse(Int, m[2]), parse(Int, m[3]), parse(Int, m[4]), parse(Int, m[5]), parse(Int, m[6]), parse(Int, m[7]))
end

input = readlines(open("input-22"))
test = readlines(open("test-22"))

# Explicitly run the instruction on the -50:50 cube.
function run_naive(instrs::Vector{Instr})::Array{Bool,3}
    grid = zeros(Bool, (101, 101, 101))
    for instr in instrs
        c_instr = clip(instr)
        for x = c_instr.x1:c_instr.x2, y = c_instr.y1:c_instr.y2, z = c_instr.z1:c_instr.z2
            grid[x+51, y+51, z+51] = c_instr.is_on
        end
    end
    grid
end

function clip(instr::Instr)::Instr
    x1 = max(instr.x1, -50)
    x2 = min(instr.x2, 50)
    y1 = max(instr.y1, -50)
    y2 = min(instr.y2, 50)
    z1 = max(instr.z1, -50)
    z2 = min(instr.z2, 50)
    Instr(instr.is_on, x1, x2, y1, y2, z1, z2)
end

@assert 590784 == sum(run_naive(parse_line.(test)))
@assert 602574 == sum(run_naive(parse_line.(input)))

# For part two, we have to consider the entire region.
# I do it by operating not on individual voxels, but on cubes.

struct Cube
    x1::Int
    x2::Int
    y1::Int
    y2::Int
    z1::Int
    z2::Int
end

function cube_size(cube::Cube)::Int
    # (x2 - x1 + 1) * (y2 - y1 + 1) * (z2 - z1 + 1)
    (cube.x2 - cube.x1 + 1) * (cube.y2 - cube.y1 + 1) * (cube.z2 - cube.z1 + 1)
end

# I is enough to know how to turn cubes off with conflict resolution, because
# to turn a cube on, I can also turn it off first and then turn it on again.

function run(instrs::Vector{Instr})::Int
    cubes = []
    for instr in instrs
        instr_cube = Cube(instr.x1, instr.x2, instr.y1, instr.y2, instr.z1, instr.z2)
        new_cubes = []
        for plus_cube in cubes
            sub_cubes = turn_off(plus_cube, instr_cube)
            append!(new_cubes, sub_cubes)
        end
        if instr.is_on
            push!(new_cubes, instr_cube)
        end
        cubes = new_cubes
    end
    sum(cube_size.(cubes))
end

function turn_off(plus_cube::Cube, minus_cube::Cube)::Vector{Cube}
    result1 = []
    push!(result1, Cube(plus_cube.x1, min(minus_cube.x1 - 1, plus_cube.x2), plus_cube.y1, plus_cube.y2, plus_cube.z1, plus_cube.z2))
    push!(result1, Cube(max(minus_cube.x2 + 1, plus_cube.x1), plus_cube.x2, plus_cube.y1, plus_cube.y2, plus_cube.z1, plus_cube.z2))
    push!(result1, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), plus_cube.y1, min(minus_cube.y1 - 1, plus_cube.y2), plus_cube.z1, plus_cube.z2))
    push!(result1, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), max(minus_cube.y2 + 1, plus_cube.y1), plus_cube.y2, plus_cube.z1, plus_cube.z2))
    push!(result1, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), max(minus_cube.y1, plus_cube.y1), min(minus_cube.y2, plus_cube.y2), plus_cube.z1, min(minus_cube.z1 - 1, plus_cube.z2)))
    push!(result1, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), max(minus_cube.y1, plus_cube.y1), min(minus_cube.y2, plus_cube.y2), max(minus_cube.z2 + 1, plus_cube.z1), plus_cube.z2))
    result = []
    for cube in result1
        if cube.x1 <= cube.x2 && cube.y1 <= cube.y2 && cube.z1 <= cube.z2
            push!(result, cube)
        end
    end
    result
end

function random_cube()::Cube
    v = rand(Int, 6) .% 100
    cube = Cube(v[1], v[1] + abs(v[2]) + 1, v[3], v[3] + abs(v[4]) + 1, v[5], v[5] + abs(v[6]) + 1)
    @assert cube.x1 < cube.x2
    @assert cube.y1 < cube.y2
    @assert cube.z1 < cube.z2
    cube
end

test2 = readlines(open("test-22-2"))
@assert 2758514936282235 == run(parse_line.(test2))
#@show run(parse_line.(input))

# Error 1292063059899010 is higher than the expected value.
# Also, my test result of 2759445304032930 is still off by 0.03%.

# Likely also wrong: 1288698231555214

# After fixing the "1 wide cubes removed" bug: 1288707160324706

# First wrong result was 0.2% off.
# Second wrong result was 0.0007% off.