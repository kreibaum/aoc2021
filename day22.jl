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