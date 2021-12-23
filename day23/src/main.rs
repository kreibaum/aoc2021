// Day 23: Amphipod //
//////////////////////

// Ignore all dead code warnings
#![allow(dead_code)]

use std::fmt::Debug;

use pathfinding::directed::astar::astar;

// Example input part 1
// #############
// #...........#
// ###B#C#B#D###
//   #A#D#C#A#
//   #########

// Puzzle input part 1
// #############
// #...........#
// ###D#A#A#D###
//   #C#C#B#B#
//   #########

// Example input part 2
// #############
// #...........#
// ###B#C#B#D###
//   #D#C#B#A#
//   #D#B#A#C#
//   #A#D#C#A#
//   #########

// Puzzle input part 2
// #############
// #...........#
// ###D#A#A#D###
//   #D#C#B#A#
//   #D#B#A#C#
//   #C#C#B#B#
//   #########

const DEPTH: usize = 4;

// #############
// #12.3.4.5.67#
// ###1#5#.#.###
//   #2#.#.#.#
//   #3#.#.#.#
//   #4#.#.#.#
//   #########

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct Cave([u8; 7 + 4 * DEPTH]);

const STEP_COST: [usize; 5] = [0, 1, 10, 100, 1000];

#[inline]
fn step_cost(amphipod: u8) -> usize {
    STEP_COST[amphipod as usize]
}

impl Cave {
    // Note that room is 1-indexed
    fn room(&self, room: usize, seat: usize) -> u8 {
        self.0[7 + (room - 1) * DEPTH + seat]
    }

    fn room_ready_for_move_in(&self, room: usize) -> bool {
        debug_assert!(0 < room && room < 5);
        for seat in 0..DEPTH {
            let amphipod = self.room(room, seat);
            if amphipod != 0 && amphipod != room as u8 {
                return false;
            }
        }
        true
    }

    fn open_hallway_path(&self, room: usize, hallway_location: usize) -> bool {
        debug_assert!(0 < room && room < 5);
        debug_assert!(hallway_location < 7);

        let l = EXIT_L[room];
        let r = EXIT_R[room];

        if hallway_location <= l {
            for i in (hallway_location + 1)..=l {
                if self.hallway(i) != 0 {
                    return false;
                }
            }
            return true;
        }

        if hallway_location >= r {
            for i in r..hallway_location {
                if self.hallway(i) != 0 {
                    return false;
                }
            }
            return true;
        }
        panic!(
            "Range related internal error in open_hallway_path({:?}, {}, {})",
            self, room, hallway_location
        );
    }

    fn hallway(&self, i: usize) -> u8 {
        debug_assert!(i < 7);
        self.0[i]
    }

    fn set_hallway(&mut self, i: usize, arg: u8) {
        debug_assert!(i < 7);
        debug_assert!(arg < 5);
        self.0[i] = arg;
    }

    // Assumes an amphipod is right outside the room and pulls it into the deepest
    // free seat in the room. Returns the steps this takes.
    // Remember that rooms are 1-indexed.
    fn push_room(&mut self, room: usize) -> usize {
        debug_assert!(0 < room && room < 5);
        let mut steps = DEPTH;
        let doorstep = 7 + (room - 1) * DEPTH - 1; // Not a real index, but becomes one +1.
        while steps > 0 {
            if self.0[doorstep + steps] == 0 {
                self.0[doorstep + steps] = room as u8;
                return steps;
            }
            steps -= 1;
        }
        panic!("Tried to push room {} into a full room", room);
    }

    // Removes the top amphipod from the room and returns the step count used.
    fn pop_room(&mut self, room: usize) -> usize {
        debug_assert!(0 < room && room < 5);
        let doorstep = 7 + (room - 1) * DEPTH - 1; // Not a real index, but becomes one +1.
        for steps in 1..=DEPTH {
            if self.0[doorstep + steps] != 0 {
                self.0[doorstep + steps] = 0;
                return steps;
            }
        }
        panic!("Tried to pop room {} from an empty room", room);
    }

    // Returns the top amphipod in the room.
    // You should only need to call this if you already made sure that there
    // are foreign amphipods in the room.
    fn top(&self, room: usize) -> u8 {
        debug_assert!(0 < room && room < 5);
        for seat in 0..DEPTH {
            let amphipod = self.room(room, seat);
            if amphipod != 0 {
                return amphipod;
            }
        }
        panic!(
            "Tried to get top amphipod in room {} but there were none",
            room
        );
    }

    fn reachable(&self, room: usize) -> (usize, usize) {
        debug_assert!(0 < room && room < 5);
        let mut l = EXIT_R[room];
        for i in (0..=EXIT_L[room]).rev() {
            if self.hallway(i) == 0 {
                l = i;
            } else {
                break;
            }
        }
        let mut r = EXIT_L[room];
        for i in EXIT_R[room]..7 {
            if self.hallway(i) == 0 {
                r = i;
            } else {
                break;
            }
        }
        (l, r)
    }
}

fn heuristic1(cave: &Cave) -> usize {
    let mut total = 0;
    // For each Amphipod in the hallway, calculate how long it will take home.
    for i in 0..7 {
        let amphipod = cave.0[i];
        if amphipod > 0 {
            total += center_steps(amphipod, i) * step_cost(amphipod);
            total += DEPTH * step_cost(amphipod);
        }
    }
    // For each Amphipod that is in the wrong room, calculate how long it will
    // take home.
    for room in 1..=4 {
        // Rooms are 1-indexed to match amphipod indexing.
        for seat in 0..DEPTH {
            let amphipod = cave.room(room, seat);
            if amphipod > 0 && amphipod as usize != room {
                total += (seat + 1) * step_cost(amphipod); // Go to the top
                total +=
                    2 * (amphipod as isize - room as isize).abs() as usize * step_cost(amphipod); // Go to the right room
                total += DEPTH * step_cost(amphipod); // Go to the bottom
            } else if amphipod > 0 {
                // We are in the right room, just go down to the bottom.
                total += (DEPTH - seat - 1) * step_cost(amphipod);
            }
        }
    }
    // Now everything is at the bottom which is incorrect. We correct this by
    // substracting a constant.
    if total < DEPTH * (DEPTH - 1) / 2 * 1111 {
        panic!("Heuristic 1 is wrong for {:?}", cave);
    }
    total -= DEPTH * (DEPTH - 1) / 2 * 1111;

    // For the better heuristic, we can also take into account that amphipods
    // that have a different type amphipod below them will need to leaf and go
    // back in again.
    total
}

// [Get above A from 0, Get above B from 0, ...]
const CENTER_STEPS: [usize; 7 * 4] = [
    2, 4, 6, 8, // Starting at Hallway:0
    1, 3, 5, 7, // Starting at Hallway:1
    1, 1, 3, 5, // Starting at Hallway:2
    3, 1, 1, 3, // Starting at Hallway:3
    5, 3, 1, 1, // Starting at Hallway:4
    7, 5, 3, 1, // Starting at Hallway:5
    8, 6, 4, 2, // Starting at Hallway:6
];

const fn center_steps(amphipod: u8, hallway_location: usize) -> usize {
    CENTER_STEPS[(amphipod as usize - 1) + hallway_location * 4]
}

fn nbhd(cave: &Cave) -> Vec<(Cave, usize)> {
    // Amphipods only move under specific circumstances which makes the tree smaller.

    // 1. Amphipods will never move from the hallway into a room unless that room
    // is their destination room
    // 2. and that room contains no amphipods which do
    // not also have that room as their own destination.
    // 3. Amphipods don't move on the hallway.

    // If follows, that in a given cave state each room either allows entry or
    // exit, but not both.

    // We can also always prioritize "moving in" over moving out. If a move in
    // is possible, that this is one of the best moves.
    // This means if we find only one such move, we should only return only this.

    for hallway_location in 0..7 {
        let amphipod = cave.hallway(hallway_location);
        if amphipod > 0
            && cave.room_ready_for_move_in(amphipod as usize)
            && cave.open_hallway_path(amphipod as usize, hallway_location)
        {
            // Found a solution, return this as the only solution.
            let mut new_cave = cave.clone();
            let mut steps = center_steps(amphipod, hallway_location);
            new_cave.set_hallway(hallway_location, 0);
            steps += new_cave.push_room(amphipod as usize);
            return vec![(new_cave, steps * step_cost(amphipod))];
        }
    }

    // If we end up here, no one can move in and we need to generate all possible
    // movements of amphipods outside their homes.
    let mut result = Vec::new();
    for room in 1..=4 {
        // Rooms are 1-indexed
        // Check if there is a foreign amphipod in this room.
        if cave.room_ready_for_move_in(room) {
            // No foreigen amphipod, so we don't need to move out.
            continue;
        }
        let amphipod = cave.top(room);
        // Find the spaces above the room that we can move out to.
        let (l, r) = cave.reachable(room);
        for i in l..=r {
            // We can move into this space.
            let mut new_cave = cave.clone();
            let mut steps = center_steps(room as u8, i);
            new_cave.set_hallway(i, amphipod);
            steps += new_cave.pop_room(room);
            result.push((new_cave, steps * step_cost(amphipod)));
        }
    }
    result
}

// Where do you end up if you move out of a room and take a step to the left?
const EXIT_L: [usize; 5] = [666, 1, 2, 3, 4];
// Where do you end up if you move out of a room and take a step to the right?
const EXIT_R: [usize; 5] = [666, 2, 3, 4, 5];

fn success(cave: &Cave) -> bool {
    // Check if everything is where it should be.
    // Hallway must be only 0s.
    for i in 0..7 {
        if cave.hallway(i) != 0 {
            return false;
        }
    }
    // All the rooms must be filled with corresponding amphipods.
    for room in 1..=4 {
        for seat in 0..DEPTH {
            if cave.room(room, seat) != room as u8 {
                return false;
            }
        }
    }
    true
}

fn main() {
    // Part 1:
    // #############
    // #...........#
    // ###D#A#A#D###
    //   #C#C#B#B#
    //   #########
    // let cave = Cave([0, 0, 0, 0, 0, 0, 0, 4, 3, 1, 3, 1, 2, 4, 2]);

    // #############
    // #...........#
    // ###D#A#A#D###
    //   #D#C#B#A#
    //   #D#B#A#C#
    //   #C#C#B#B#
    //   #########
    let cave = Cave([
        0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 3, 1, 3, 2, 3, 1, 2, 1, 2, 4, 1, 3, 2,
    ]);

    let solution = astar(
        &cave,
        |cave| nbhd(cave),
        |cave| heuristic1(cave),
        // |_cave| 0,
        |cave| success(cave),
    )
    .expect("No path found.");

    println!("Part 2 costs {} energy.", solution.1);
}

/* // Only enable this when DEPTH == 2.
// Test this module.
#[cfg(test)]
mod test {
    use super::*;
    #[test]
    fn test_center_steps() {
        assert_eq!(center_steps(4, 2), 5);
        assert_eq!(center_steps(3, 2), 3);
    }

    const TARGET: Cave = Cave([0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4]);

    #[test]
    fn test_heuristic_on_final_state_is_zero() {
        assert_eq!(heuristic1(&TARGET), 0);
    }

    #[test]
    fn test_heuristic_1() {
        // #############
        // #...........#
        // ###D#B#C#A###
        //   #A#B#C#D#
        //   #########
        let cave = Cave([0, 0, 0, 0, 0, 0, 0, 4, 1, 2, 2, 3, 3, 1, 4]);
        assert_eq!(heuristic1(&cave), 8008);
    }

    #[test]
    fn test_heuristic2() {
        // #############
        // #...........#
        // ###D#A#A#D###
        //   #C#C#B#B#
        //   #########
        let cave = Cave([0, 0, 0, 0, 0, 0, 0, 4, 3, 1, 3, 1, 2, 4, 2]);
        assert_eq!(heuristic1(&cave), 10441);
    }

    #[test]
    fn test_heuristic3() {
        // #############
        // #.. . . C .D#
        // ###A#B#.#.###
        //   #A#B#C#D#
        //   #########
        let cave = Cave([0, 0, 0, 0, 3, 0, 4, 1, 1, 2, 2, 0, 3, 0, 4]);
        assert_eq!(heuristic1(&cave), 3200);
    }

    #[test]
    fn test_nbhd1() {
        // #############
        // #.._D_._._..#
        // ###A#B#C#.###
        //   #A#B#C#D#
        //   #########
        let cave = Cave([0, 0, 4, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 0, 4]);
        let nbhd = nbhd(&cave);
        assert_eq!(nbhd.len(), 1);
        assert_eq!(nbhd[0].1, 6000);
        assert_eq!(nbhd[0].0, TARGET);
    }

    #[test]
    fn test_nbhd2() {
        // #############
        // #.._D_._._..#
        // ###A#B#.#D###
        //   #A#B#C#C#
        //   #########
        let cave = Cave([0, 0, 4, 0, 0, 0, 0, 1, 1, 2, 2, 0, 3, 4, 3]);

        assert_eq!(cave.reachable(4), (3, 6));

        let nbhd = nbhd(&cave);
        assert_eq!(nbhd.len(), 4);
        assert_eq!(nbhd[0].1, 4000);
        assert_eq!(nbhd[1].1, 2000);
        assert_eq!(nbhd[2].1, 2000);
        assert_eq!(nbhd[3].1, 3000);
    }

    #[test]
    fn test_nbhd3() {
        // #############
        // #.._D_._C_D.#
        // ###A#B#.#.###
        //   #A#B#C#.#
        //   #########
        let cave = Cave([0, 0, 4, 0, 3, 4, 0, 1, 1, 2, 2, 0, 3, 0, 0]);
        assert_eq!(cave.reachable(3), (3, 3));

        assert!(!cave.open_hallway_path(4, 2));
        assert!(cave.open_hallway_path(3, 4));
        assert!(cave.open_hallway_path(4, 5));

        let nbhd = nbhd(&cave);
        assert_eq!(nbhd.len(), 1);
        assert_eq!(nbhd[0].1, 200);
    }

    #[test]
    fn test_success() {
        assert!(success(&TARGET));

        let cave = Cave([0, 0, 4, 0, 0, 0, 0, 1, 1, 2, 2, 0, 3, 4, 3]);
        assert!(!success(&cave));

        let cave = Cave([0, 0, 0, 0, 0, 0, 0, 4, 3, 1, 3, 1, 2, 4, 2]);
        assert!(!success(&cave));
    }

    #[test]
    // #[ignore = "reason"]
    fn test_mini_search() {
        // #############
        // #.._D_._._..#
        // ###A#B#.#D###
        //   #A#B#C#C#
        //   #########
        let cave = Cave([0, 0, 4, 0, 0, 0, 0, 1, 1, 2, 2, 0, 3, 4, 3]);
        let solution = astar(
            &cave,
            |cave| nbhd(cave),
            |cave| heuristic1(cave),
            |cave| success(cave),
        )
        .expect("No path found.");

        println!("{:?}", solution);

        assert_eq!(solution.0.len(), 6);
        assert_eq!(solution.1, 11500);

        assert_eq!(
            solution.0[0],
            Cave([0, 0, 4, 0, 0, 0, 0, 1, 1, 2, 2, 0, 3, 4, 3])
        );
        assert_eq!(
            solution.0[1],
            Cave([0, 0, 4, 0, 0, 4, 0, 1, 1, 2, 2, 0, 3, 0, 3])
        );
        assert_eq!(
            solution.0[2],
            Cave([0, 0, 4, 0, 3, 4, 0, 1, 1, 2, 2, 0, 3, 0, 0])
        );
        assert_eq!(
            solution.0[3],
            Cave([0, 0, 4, 0, 0, 4, 0, 1, 1, 2, 2, 3, 3, 0, 0])
        );
        assert_eq!(
            solution.0[4],
            Cave([0, 0, 0, 0, 0, 4, 0, 1, 1, 2, 2, 3, 3, 0, 4])
        );
        assert_eq!(
            solution.0[5],
            Cave([0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4])
        );
    }

    #[test]
    fn test_puzzle_part1() {
        // #############
        // #...........#
        // ###D#A#A#D###
        //   #C#C#B#B#
        //   #########
        let cave = Cave([0, 0, 0, 0, 0, 0, 0, 4, 3, 1, 3, 1, 2, 4, 2]);
        let solution = astar(
            &cave,
            |cave| nbhd(cave),
            |cave| heuristic1(cave),
            |cave| success(cave),
        )
        .expect("No path found.");

        assert_eq!(solution.1, 14467);
    }
}

*/
