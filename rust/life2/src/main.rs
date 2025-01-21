/*
 * This version is not very functional (err, like the programming
 * style/paradigm). Instead, I've tried to make it go as fast as the
 * simple C version.
 */


use std::collections::HashSet;
use std::collections::HashMap;
use std::thread::sleep;
use std::time::Duration;
use std::time::Instant;

type Coord = (i32, i32);
type LiveSet = HashSet<Coord>;
const GENERATIONS: i32 = 1000;
const SHOW_WORK: bool = false;
const HUMAN_WAIT: Duration = Duration::from_millis(1000/30);

fn tick(state: LiveSet) -> LiveSet {
    let mut neighbor_count: HashMap<Coord, usize> = HashMap::with_capacity(state.len() * 8);
    for coord in state.iter() {
	let (cx, cy) = coord;
	for x in -1..=1 {
	    for y in -1..=1 {
		if x != 0 || y != 0 {
		    let neighbor = (cx + x, cy + y);
		    *neighbor_count.entry(neighbor).or_default() += 1;
		}
	    }
	}
    }
    let mut result : HashSet<Coord> = HashSet::with_capacity(neighbor_count.len());
    result.extend(neighbor_count
	.iter()
	.filter(|&(coord, &count)| count == 3 || (count == 2 && state.contains(coord)))
	.map(|(&coord, &_count)| coord));
    return result;
}

fn clear_screen() {
    print!("\x1b[2J");
    print!("\x1b[;H");
}

fn print_board(live_set: &LiveSet) {
    clear_screen();
    for y in -12..13 {
	for x in -40..40 {
	    if live_set.contains(&(x, y)) {
		print!("#")
	    } else {
		print!(" ")
	    }
	}
	print!("\n")
    }
    sleep(HUMAN_WAIT);
}

fn run() {
    let now = Instant::now();
    let r_pentomino = [(0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)];
    let mut board : HashSet<Coord> = HashSet::from_iter(r_pentomino.into_iter());
    for _gen in 0..GENERATIONS {
	if SHOW_WORK {
	    print_board(&board);
	}
	board = tick(board);
    }
    print!("{} generations per second\n",
	   f64::from(GENERATIONS) / now.elapsed().as_secs_f64());
}

fn main() {
    for _ in 0..5 {
	run();
    }
}
