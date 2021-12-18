## Day 18: Snailfish ##
#######################

# This is a rewrite, this time using a better data structure & functional programming

abstract type Tree end

struct Pair <: Tree
    left::Tree
    right::Tree
end

struct Leaf <: Tree
    value::Int
end

Pair(l::Int, r::Int) = Pair(Leaf(l), Leaf(r))

parse(data::Int)::Tree = Leaf(data)
parse(data::Array)::Tree = Pair(parse(data[1]), parse(data[2]))

# For debugging
s(pair::Pair)::String = "{$(s(pair.left)),$(s(pair.right))}"
s(leaf::Leaf) = "$(leaf.value)"

function split_one(leaf::Leaf)::Tuple{Tree,Symbol}
    if leaf.value >= 10
        (Pair(Int(floor(leaf.value / 2)), Int(ceil(leaf.value / 2))), :split)
    else
        (leaf, :no_split)
    end
end

function split_one(pair::Pair)::Tuple{Tree,Symbol}
    new_l, action = split_one(pair.left)
    if action == :split
        (Pair(new_l, pair.right), :split)
    else
        new_r, action = split_one(pair.right)
        (Pair(pair.left, new_r), action)
    end
end

@assert (parse([[[[0, 7], 4], [[7, 8], [0, 13]]], [1, 1]]), :split) == split_one(parse([[[[0, 7], 4], [15, [0, 13]]], [1, 1]]))
@assert (parse([[[[0, 7], 4], [[7, 8], [0, [6, 7]]]], [1, 1]]), :split) == split_one(parse([[[[0, 7], 4], [[7, 8], [0, 13]]], [1, 1]]))
@assert (parse([[[[0, 7], 4], [[7, 8], [0, [6, 7]]]], [1, 1]]), :no_split) == split_one(parse([[[[0, 7], 4], [[7, 8], [0, [6, 7]]]], [1, 1]]))

OInt = Union{Int,Nothing}

left_add(tree::Tree, _::Nothing) = tree
left_add(pair::Pair, value::Int) = Pair(left_add(pair.left, value), pair.right)
left_add(leaf::Leaf, value::Int) = Leaf(leaf.value + value)

right_add(tree::Tree, _::Nothing) = tree
right_add(pair::Pair, value::Int) = Pair(pair.left, right_add(pair.right, value))
right_add(leaf::Leaf, value::Int) = Leaf(leaf.value + value)

@assert parse([[6, 2], 6]) == left_add(parse([[1, 2], 6]), 5)
@assert parse([[1, 2], 11]) == right_add(parse([[1, 2], 6]), 5)

ExplodeData = Tuple{OInt,Tree,OInt,Symbol}

function explode_one(tree::Tree)::Tuple{Tree,Symbol}
    _, new_tree, _, action = explode_one(tree, 1)
    (new_tree, action)
end
explode_one(leaf::Leaf, _::Int)::ExplodeData = (nothing, leaf, nothing, :no_explode)
function explode_one(pair::Pair, layer::Int)::ExplodeData
    if layer > 4
        # Found a deeply nested pair, explode it
        # First, assert that there is nothing on layer 6
        @assert typeof(pair.left) == Leaf
        @assert typeof(pair.left) == Leaf
        (pair.left.value, Leaf(0), pair.right.value, :explode)
    else
        # Check if any of the children explodes. If they do, carry up the OInt
        l_int, new_l, r_int, action = explode_one(pair.left, layer + 1)
        if action == :explode
            (l_int, Pair(new_l, left_add(pair.right, r_int)), nothing, :explode)
        else
            l_int, new_r, r_int, action = explode_one(pair.right, layer + 1)
            (nothing, Pair(right_add(pair.left, l_int), new_r), r_int, action)
        end
    end
end

@assert (parse([[[[0, 9], 2], 3], 4]), :explode) == explode_one(parse([[[[[9, 8], 1], 2], 3], 4]))
@assert (parse([7, [6, [5, [7, 0]]]]), :explode) == explode_one(parse([7, [6, [5, [4, [3, 2]]]]]))
@assert (parse([[6, [5, [7, 0]]], 3]), :explode) == explode_one(parse([[6, [5, [4, [3, 2]]]], 1]))
@assert (parse([[3, [2, [8, 0]]], [9, [5, [4, [3, 2]]]]]), :explode) == explode_one(parse([[3, [2, [1, [7, 3]]]], [6, [5, [4, [3, 2]]]]]))
@assert (parse([[3, [2, [8, 0]]], [9, [5, [7, 0]]]]), :explode) == explode_one(parse([[3, [2, [8, 0]]], [9, [5, [4, [3, 2]]]]]))

function normalize(tree::Tree)::Tree
    new_tree, action = explode_one(tree)
    if action == :explode
        normalize(new_tree)
    else
        new_tree, action = split_one(new_tree)
        if action == :split
            normalize(new_tree)
        else
            new_tree
        end
    end
end

@assert parse([[[[0, 7], 4], [[7, 8], [6, 0]]], [8, 1]]) == normalize(parse([[[[[4, 3], 4], 4], [7, [[8, 4], 9]]], [1, 1]]))

add(t1::Tree, t2::Tree)::Tree = normalize(Pair(t1, t2))
sum(trees::Vector)::Tree = foldl(add, trees)

@assert sum(parse.([[[[0, [4, 5]], [0, 0]], [[[4, 5], [2, 6]], [9, 5]]],
    [7, [[[3, 7], [4, 3]], [[6, 3], [8, 8]]]],
    [[2, [[0, 8], [3, 4]]], [[[6, 7], 1], [7, [1, 6]]]],
    [[[[2, 4], 7], [6, [0, 5]]], [[[6, 8], [2, 8]], [[2, 1], [4, 5]]]],
    [7, [5, [[3, 8], [1, 4]]]],
    [[2, [2, 2]], [8, [8, 1]]],
    [2, 9],
    [1, [[[9, 3], 9], [[9, 0], [0, 7]]]],
    [[[5, [7, 4]], 7], 1],
    [[[[4, 2], 2], 6], [8, 7]]])) == parse([[[[8, 7], [7, 7]], [[8, 6], [7, 7]]], [[[0, 7], [6, 6]], [8, 7]]])


include("test-18.jl")
include("input-18.jl")

magnitude(leaf::Leaf)::Int = leaf.value
magnitude(pair::Pair)::Int = 3 * magnitude(pair.left) + 2 * magnitude(pair.right)

@assert 4140 == magnitude(sum(parse.(day18_test)))
@assert 4469 == magnitude(sum(parse.(day18_input)))

function max_magnitude(list_of_trees::Vector)::Int
    best = 0
    for i = 1:length(list_of_trees), j = 1:length(list_of_trees)
        if i == j
            continue
        end
        best = max(best, magnitude(add(list_of_trees[i], list_of_trees[j])))
    end
    best
end

@assert 3993 == max_magnitude(parse.(day18_test))
@assert 4770 == max_magnitude(parse.(day18_input))
