# Day one

d1_test = [199,200,208,210,200,207,240,269,260,263]
day_1_input = parse.(Int, readlines(open("input-01")))

function depth_count(depth_array)
    counter = 0
    for i in 1:(length(depth_array)-1)
        if depth_array[i] < depth_array[i+1]
            counter = counter + 1
        end
    end
    counter
end

@assert 7 == @show depth_count(d1_test)
@assert 1532 == @show depth_count(day_1_input)


function sliding_window_increase(depth_array)
    counter = 0
    for i in 1:(length(depth_array)-3)
        if depth_array[i] < depth_array[i+3]
            counter = counter + 1
        end
    end
    counter
end

@assert 5 == @show sliding_window_increase(d1_test)
@assert 1532 == @show sliding_window_increase(day_1_input)