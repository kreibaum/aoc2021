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
