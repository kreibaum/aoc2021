## Day 18: Snailfish ##
#######################

# Each number is a tree

function reduce!(tree)
    # Search for the leftmost pair to explode
    explode!(tree, 0)
end

# Every number has an index. I think using this index can make the code cleaner.

bigness(tree::Int) = 1
bigness(tree::Array) = sum(bigness.(tree))

@assert bigness([1, 2]) == 2
@assert bigness([[1, 2], 3]) == 3
@assert bigness([9, [8, 7]]) == 3
@assert bigness([[1, 9], [8, 5]]) == 4
@assert bigness([[[[1, 2], [3, 4]], [[5, 6], [7, 8]]], 9]) == 9

function info_about_index(tree::Int, index)
    @assert index == 1
    (tree, 0)
end

function info_about_index(tree::Array, index)
    # Return the number at the given index + information
    left_bigness = 0 # always left_bigness < index
    for t in tree
        sub_bigness = bigness(t)
        if left_bigness + sub_bigness < index
            left_bigness += sub_bigness
        else
            sub_v, sub_d = info_about_index(t, index - left_bigness)
            return (sub_v, sub_d + 1)
        end
    end
    throw("Out of bounds error")
end

@assert info_about_index([1, 2], 1) == (1, 1)
@assert info_about_index([9, [8, 7]], 2) == (8, 2)

function delete_at_index!(tree::Array, index)
    left_bigness = 0
    for i = 1:length(tree)
        t = tree[i]
        sub_bigness = bigness(t)
        if left_bigness + sub_bigness < index
            left_bigness += sub_bigness
        elseif typeof(t) == Int
            popat!(tree, i)
            return tree
        else
            tree[i] = n(t)
            delete_at_index!(tree[i], index - left_bigness)
            if length(tree[i]) == 1
                tree[i] = tree[i][1]
            end
            return tree
        end
    end
    throw("Out of bounds error")
end

@assert [9, 8] == delete_at_index!([9, [8, 7]], 3)
@assert [9, [8, 5], 1] == delete_at_index!([[1, 9], [8, 5], 1], 1)
@assert [1, [8, 5], 1] == delete_at_index!([[1, 9], [8, 5], 1], 2)
@assert [[1, 9], 5, 1] == delete_at_index!([[1, 9], [8, 5], 1], 3)
@assert [[1, 9], 8, 1] == delete_at_index!([[1, 9], [8, 5], 1], 4)
@assert [21, [[0, [7, 6]], [[7, 6], [4, 7]]]] == delete_at_index!(n([21, [[[0, 2], [7, 6]], [[7, 6], [4, 7]]]]), 3)

function set_at!(tree::Array, index, value)
    left_bigness = 0
    for i = 1:length(tree)
        t = tree[i]
        sub_bigness = bigness(t)
        if left_bigness + sub_bigness < index
            left_bigness += sub_bigness
        elseif typeof(t) == Int
            @assert index - left_bigness == 1
            tree[i] = value
            return tree
        else
            set_at!(t, index - left_bigness, value)
            if length(t) == 1
                tree[i] = t[1]
            end
            return tree
        end
    end
    throw("Out of bounds error")
end

@assert [[7, 9], [8, 5], 1] == set_at!([[1, 9], [8, 5], 1], 1, 7)
@assert [[1, 7], [8, 5], 1] == set_at!([[1, 9], [8, 5], 1], 2, 7)
@assert [[1, 9], [7, 5], 1] == set_at!([[1, 9], [8, 5], 1], 3, 7)
@assert [[1, 9], [8, 7], 1] == set_at!([[1, 9], [8, 5], 1], 4, 7)
@assert [[1, 9], [8, 5], 7] == set_at!([[1, 9], [8, 5], 1], 5, 7)

function explode_one!(tree::Array{Any,1})
    for i = 1:bigness(tree)
        left_value, depth = info_about_index(tree, i)
        if depth > 5
            throw("Depth too big, malformed tree")
        elseif depth == 5
            right_value, depth = info_about_index(tree, i + 1)

            if i - 1 >= 1
                set_at!(tree, i - 1, left_value + info_about_index(tree, i - 1)[1])
            end
            if i + 2 <= bigness(tree)
                set_at!(tree, i + 2, right_value + info_about_index(tree, i + 2)[1])
            end
            set_at!(tree, i, 0)
            delete_at_index!(tree, i + 1)
            return tree
        end
    end
end

"""Normalize away the type issuses I see when entering literals like [[1,2],[3,4]]"""
function n(tree::Array)::Array{Any,1}
    result = Array{Any,1}()
    for t in tree
        push!(result, n(t))
    end
    tree
end

n(tree::Int)::Int = tree

@assert [1, [8, 5]] == delete_at_index!(n([[1, 9], [8, 5]]), 2)

@assert [[[[0, 9], 2], 3], 4] == explode_one!([[[[[9, 8], 1], 2], 3], 4])
@assert [7, [6, [5, [7, 0]]]] == explode_one!([7, [6, [5, [4, [3, 2]]]]])
@assert [[6, [5, [7, 0]]], 3] == explode_one!([[6, [5, [4, [3, 2]]]], 1])
@assert [[3, [2, [8, 0]]], [9, [5, [4, [3, 2]]]]] == explode_one!(n([[3, [2, [1, [7, 3]]]], [6, [5, [4, [3, 2]]]]]))
@assert [[3, [2, [8, 0]]], [9, [5, [7, 0]]]] == explode_one!(n([[3, [2, [8, 0]]], [9, [5, [4, [3, 2]]]]]))


function split_one!(tree::Array{Any,1})
    for i = 1:length(tree)
        t = tree[i]
        if typeof(t) == Int && t >= 10
            tree[i] = n([Int(floor(t / 2)), Int(ceil(t / 2))])
            return (tree, :split)
        elseif typeof(t) == Int
            continue
        else
            tree[i] = n(t)
            _, action = split_one!(tree[i])
            if action == :split
                return (tree, :split)
            end
        end
    end
    (tree, :no_split)
end

@assert ([[[[0, 7], 4], [[7, 8], [0, 13]]], [1, 1]], :split) == split_one!(n([[[[0, 7], 4], [15, [0, 13]]], [1, 1]]))
@assert ([[[[0, 7], 4], [[7, 8], [0, [6, 7]]]], [1, 1]], :split) == split_one!(n([[[[0, 7], 4], [[7, 8], [0, 13]]], [1, 1]]))
@assert ([[[[0, 7], 4], [[7, 8], [0, [6, 7]]]], [1, 1]], :no_split) == split_one!(n([[[[0, 7], 4], [[7, 8], [0, [6, 7]]]], [1, 1]]))

function reduce!(tree::Array{Any,1})
    while true
        # Try to explode a pair
        old_bigness = bigness(tree)
        explode_one!(tree)
        if bigness(tree) != old_bigness
            continue
        end

        # Try to split a pair
        _, action = split_one!(tree)
        if action == :split
            continue
        end

        # No more changes
        return tree
    end
end

@assert [[[[0, 7], 4], [[7, 8], [6, 0]]], [8, 1]] == reduce!(n([[[[[4, 3], 4], 4], [7, [[8, 4], 9]]], [1, 1]]))

include("test-17.jl")
include("input-17.jl")

function final_sum(list_of_trees)
    sum = list_of_trees[1]
    for i = 2:length(list_of_trees)
        sum = reduce!(n([sum, deepcopy(list_of_trees[i])]))
    end
    sum
end

@assert [[[[6, 6], [7, 6]], [[7, 7], [7, 0]]], [[[7, 7], [7, 7]], [[7, 8], [9, 9]]]] == final_sum(day17_test)

magnitude(tree::Int) = tree
magnitude(tree::Array) = 3 * magnitude(tree[1]) + 2 * magnitude(tree[2])

@assert 4140 == magnitude([[[[6, 6], [7, 6]], [[7, 7], [7, 0]]], [[[7, 7], [7, 7]], [[7, 8], [9, 9]]]])
@assert 4469 == magnitude(final_sum(day17_input))

include("test-17.jl")
include("input-17.jl")

function max_magnitude(list_of_trees)
    best = 0
    for i = 1:length(list_of_trees), j = 1:length(list_of_trees)
        if i == j
            continue
        end
        best = max(best, magnitude(final_sum(n(deepcopy([list_of_trees[i], list_of_trees[j]])))))
    end
    best
end

@assert 3993 == max_magnitude(day17_test)
@assert 4770 == max_magnitude(day17_input)