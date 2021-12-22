## Day 20: Trench Map ##
########################

day20_input = (10, 3)
day20_test = (4, 8)

# Given two player positions, simulates the dirac dice game
function simulate(a, b)
    dice = 10
    score_a = 0
    score_b = 0
    rolls = 0
    while true
        for _ = 1:3
            rolls += 1
            dice = wrap(dice + 1)
            a = wrap(a + dice)
        end
        score_a += a
        if score_a >= 1000
            return score_b, rolls
        end
        # @show score_a
        for _ = 1:3
            rolls += 1
            dice = wrap(dice + 1)
            b = wrap(b + dice)
        end
        score_b += b
        if score_b >= 1000
            return score_a, rolls
        end
        # @show score_b
    end
end

wrap(position) = position > 10 ? position - 10 : position

# Part 2, this looks more tricky. I thing the solution is to group universes
# that are identical and reduce them to a number.

# What is the state of the universe? (a, b, score_a, score_b). There are
# 10 * 10 * 31 * 31 = 96100 possible states (including 20 + 10 = 30 and 0 score)

function dirac(a, b)
    # To make indexing easier, players start with score 1 and win with 22 points.
    states = zeros(Int, (10, 10, 31, 31))
    states[a, b, 1, 1] = 1
    a_wins = 0
    b_wins = 0
    while sum(states) > 0
        @show "loop", sum(states), a_wins, b_wins
        # Evolve the metaverse
        new_states = zeros(Int, (10, 10, 31, 31))
        for a = 1:10, b = 1:10, score_a = 1:21, score_b = 1:21
            if states[a, b, score_a, score_b] > 0
                new_states .+= dirac_one_a(a, b, score_a, score_b) .* states[a, b, score_a, score_b]
            end
        end
        states = new_states
        # Filter out states that are already won and sum them up.
        for a = 1:10, b = 1:10, score_a = 22:31, score_b = 1:31
            a_wins += states[a, b, score_a, score_b]
            states[a, b, score_a, score_b] = 0
        end
        # Evolve the metaverse
        new_states = zeros(Int, (10, 10, 31, 31))
        for a = 1:10, b = 1:10, score_a = 1:21, score_b = 1:21
            if states[a, b, score_a, score_b] > 0
                new_states .+= dirac_one_b(a, b, score_a, score_b) .* states[a, b, score_a, score_b]
            end
        end
        states = new_states
        # Filter out states that are already won and sum them up.
        for a = 1:10, b = 1:10, score_a = 1:31, score_b = 22:31
            b_wins += states[a, b, score_a, score_b]
            states[a, b, score_a, score_b] = 0
        end
    end
    (a_wins, b_wins)
end

# You can roll 3*3*3 = 27 different universes which collapse into
roll_count = Dict(3 => 1, 4 => 3, 5 => 6, 6 => 7, 7 => 6, 8 => 3, 9 => 1)
@assert sum(values(roll_count)) == 27

function dirac_one_a(a, b, score_a, score_b)::Array
    states = zeros(Int, (10, 10, 31, 31))
    for roll in keys(roll_count)
        new_a = wrap(a + roll)
        states[new_a, b, score_a+new_a, score_b] = roll_count[roll]
    end
    states
end

function dirac_one_b(a, b, score_a, score_b)::Array
    states = zeros(Int, (10, 10, 31, 31))
    for roll in keys(roll_count)
        new_b = wrap(b + roll)
        states[a, new_b, score_a, score_b+new_b] = roll_count[roll]
    end
    states
end