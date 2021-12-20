
## Day 19: Beacon Scanner ##
############################

# Wow, this is an interesting problem. Definitely not just "take known algorithm".

# Calculating the "signature" of a scanner can help me match scanners.
# This is the set of all differences of the beacons seen by the scanner.
# That is translation invariant, but still not rotation invariant.

# Rotation invariant would be the "square distance signature", so I better start
# with that.

function p(data::Vector{String})::Vector{Tuple{Int,Vector}}
    scanners = []
    current_scanner_id = nothing
    current_scanner_seen = []
    for line in data
        m = match(r"--- scanner ([0-9]+) ---", line)
        if m !== nothing
            if current_scanner_id !== nothing
                push!(scanners, (parse(Int, current_scanner_id), current_scanner_seen))
            end
            current_scanner_id = m[1]
            current_scanner_seen = []
        else
            m = match(r"(-?[0-9]+),(-?[0-9]+),(-?[0-9]+)", line)
            if m !== nothing
                push!(current_scanner_seen, (parse(Int, m[1]), parse(Int, m[2]), parse(Int, m[3])))
            end
        end
    end
    push!(scanners, (parse(Int, current_scanner_id), current_scanner_seen))
    scanners
end

test = p(readlines(open("test-19")))
input = p(readlines(open("input-19")))

function sig(sensor_data)::Set{Tuple{Int,Int,Int}}
    sig = Set()
    # To make sure there is no issue with the direction the deltas are pointing
    # to, I include them in both directions.
    for b1 in sensor_data, b2 in sensor_data
        if b1 == b2
            continue
        end
        candidate = (b1[1] - b2[1], b1[2] - b2[2], b1[3] - b2[3])
        push!(sig, candidate)
    end
    sig
end

rot_x_r1((x, y, z)) = (x, y, z)
rot_x_r2((x, y, z)) = (x, -z, y)
rot_x_r3((x, y, z)) = (x, -y, -z)
rot_x_r4((x, y, z)) = (x, z, -y)
rot_y_r1((x, y, z)) = (z, x, y)
rot_y_r2((x, y, z)) = (-y, x, z)
rot_y_r3((x, y, z)) = (-z, x, -y)
rot_y_r4((x, y, z)) = (y, x, -z)
rot_z_r1((x, y, z)) = (y, z, x)
rot_z_r2((x, y, z)) = (-z, y, x)
rot_z_r3((x, y, z)) = (-y, -z, x)
rot_z_r4((x, y, z)) = (z, -y, x)

function rotate_all(sig::Set)::Vector
    # Rotations can be specified by showing where (1,0,0) maps to + 1 of 4 rotations
    # Since we already put both signs in the signature, we can restrict x to
    # point in only 3 directions.
    result = []
    push!(result, Set(rot_x_r1.(sig)))
    push!(result, Set(rot_x_r2.(sig)))
    push!(result, Set(rot_x_r3.(sig)))
    push!(result, Set(rot_x_r4.(sig)))
    push!(result, Set(rot_y_r1.(sig)))
    push!(result, Set(rot_y_r2.(sig)))
    push!(result, Set(rot_y_r3.(sig)))
    push!(result, Set(rot_y_r4.(sig)))
    push!(result, Set(rot_z_r1.(sig)))
    push!(result, Set(rot_z_r2.(sig)))
    push!(result, Set(rot_z_r3.(sig)))
    push!(result, Set(rot_z_r4.(sig)))
end

function look_for_matches(data)
    # Look for possible matches
    for i = 1:length(data)
        sig1_base = sig(data[i][2])
        # Iterate all 12 orientations
        for sig1 in rotate_all(sig1_base)
            for j = (i+1):length(data)
                sig2 = sig(data[j][2])
                @show i, j, length(intersect(sig1, sig2))
            end
        end
    end
end

