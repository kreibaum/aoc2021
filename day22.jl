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

# I is enough to know how to turn cubes off with conflict resolution, because
# to turn a cube on, I can also turn it off first and then turn it on again.

function run(instrs::Vector{Instr})::Int
    cubes = []
end

function turn_off(plus_cube::Cube, minus_cube::Cube)::Vector{Cube}
    # The minus cube cuts the space into 6 (partially infinite) regions
    # for each such region we just intersect the plus cube with the region.
    result = []
    # Region (-inf:x1, -, -) where - = -inf:inf
    if plus_cube.x1 < minus_cube.x1
        push!(result, Cube(plus_cube.x1, min(minus_cube.x1, plus_cube.x2), plus_cube.y1, plus_cube.y2, plus_cube.z1, plus_cube.z2))
    end
    # Region (x2:inf, -, -) where - = -inf:inf
    if plus_cube.x2 > minus_cube.x2
        push!(result, Cube(max(minus_cube.x2, plus_cube.x1), plus_cube.x2, plus_cube.y1, plus_cube.y2, plus_cube.z1, plus_cube.z2))
    end
    # Region (x1:x2, -inf:y1, -) where - = -inf:inf
    # Region (x1:x2, y2:inf, -) where - = -inf:inf
    # First check if there is at least a x direction overlap.
    if plus_cube.x1 < minus_cube.x2 && plus_cube.x2 > minus_cube.x1
        # Now the y direction, -inf:y1 first
        if plus_cube.y1 < minus_cube.y1
            push!(result, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), plus_cube.y1, min(minus_cube.y1, plus_cube.y2), plus_cube.z1, plus_cube.z2))
        end
        # Region (x1:x2, y2:inf, -) where - = -inf:inf
        if plus_cube.y2 > minus_cube.y2
            push!(result, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), max(minus_cube.y2, plus_cube.y1), plus_cube.y2, plus_cube.z1, plus_cube.z2))
        end
        # Region (x1:x2, y1:y2, -inf:z1) where - = -inf:inf
        # Region (x1:x2, y1:y2, z2:inf) where - = -inf:inf
        # First check if there is at least a y direction overlap.
        if plus_cube.y1 < minus_cube.y2 && plus_cube.y2 > minus_cube.y1
            # Now the z direction, -inf:z1 first
            if plus_cube.z1 < minus_cube.z1
                push!(result, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), max(minus_cube.y1, plus_cube.y1), min(minus_cube.y2, plus_cube.y2), plus_cube.z1, min(minus_cube.z1, plus_cube.z2)))
            end
            # Region (x1:x2, y1:y2, z2:inf) where - = -inf:inf
            if plus_cube.z2 > minus_cube.z2
                push!(result, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), max(minus_cube.y1, plus_cube.y1), min(minus_cube.y2, plus_cube.y2), max(minus_cube.z2, plus_cube.z1), plus_cube.z2))
            end
        end
    end
    # Idea: Possibly this method could be rewritten by simply creating all cubes
    # and then dropping degenerate ones.
    result
end

function turn_off2(plus_cube::Cube, minus_cube::Cube)::Vector{Cube}
    result1 = []
    push!(result1, Cube(plus_cube.x1, min(minus_cube.x1, plus_cube.x2), plus_cube.y1, plus_cube.y2, plus_cube.z1, plus_cube.z2))
    push!(result1, Cube(max(minus_cube.x2, plus_cube.x1), plus_cube.x2, plus_cube.y1, plus_cube.y2, plus_cube.z1, plus_cube.z2))
    push!(result1, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), plus_cube.y1, min(minus_cube.y1, plus_cube.y2), plus_cube.z1, plus_cube.z2))
    push!(result1, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), max(minus_cube.y2, plus_cube.y1), plus_cube.y2, plus_cube.z1, plus_cube.z2))
    push!(result1, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), max(minus_cube.y1, plus_cube.y1), min(minus_cube.y2, plus_cube.y2), plus_cube.z1, min(minus_cube.z1, plus_cube.z2)))
    push!(result1, Cube(max(minus_cube.x1, plus_cube.x1), min(minus_cube.x2, plus_cube.x2), max(minus_cube.y1, plus_cube.y1), min(minus_cube.y2, plus_cube.y2), max(minus_cube.z2, plus_cube.z1), plus_cube.z2))
    result = []
    for cube in result1
        if cube.x1 < cube.x2 && cube.y1 < cube.y2 && cube.z1 < cube.z2
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

function fuzz_methods()
    for _ = 1:1000
        plus_cube = random_cube()
        minus_cube = random_cube()
        @assert turn_off(plus_cube, minus_cube) == turn_off2(plus_cube, minus_cube)
    end
end