## Day 20: Trench Map ##
########################

day20_input = readlines(open("input-20"))
day20_test = readlines(open("test-20"))

function parse_rules(input)
    rules = zeros(Bool, 512)
    for i = 1:512
        rules[i] = input[1][i] == '#'
    end
    rules
end

@assert parse_rules(day20_test)[1] == false
@assert parse_rules(day20_input)[1] == true

function parse_image(input)
    w = length(input[3])
    h = length(input) - 2
    image = zeros(Bool, (w, h))
    for x = 1:w, y = 1:h
        image[x, y] = input[y+2][x] == '#'
    end
    image
end

# An image is actually a Matrix of booleans + a boolean at infinity.
# This is because the rules can force us to update all the infinite values,
# if rules[1] == true.

function update_image(image, inf_pixel, rules)
    # Turns out we need to extend by 2 pixles on each side to also get the
    w, h = size(image) .+ (4, 4)
    output = zeros(Bool, (w, h))
    for x = 1:w, y = 1:h
        lookup = get_lookup_code(image, inf_pixel, x - 2, y - 2)
        output[x, y] = rules[lookup+1]
    end
    (output, inf_pixel ? output[512] : output[1])
end

function get_lookup_code(image, inf_pixel, cx, cy)
    w, h = size(image)
    result = 0
    for dx = -1:1, dy = -1:1
        x = cx + dx
        y = cy + dy
        if x <= 0 || x > w || y <= 0 || y > h
            result = 2 * result + inf_pixel
        else
            result = 2 * result + image[x, y]
        end
    end
    result
end

function enhance(input, n)
    rules = parse_rules(input)
    image = transpose(parse_image(input))
    inf_pixel = false
    for _ = 1:n
        image, inf_pixel = update_image(image, inf_pixel, rules)
    end
    image
end

@assert 35 == @show sum(enhance(day20_test, 2))
@assert 5819 == @show sum(enhance(day20_input, 2))

@assert 3351 == @show sum(enhance(day20_test, 50))
@assert 18516 == @show sum(enhance(day20_input, 50))
