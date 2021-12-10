use std::collections::HashSet;
use std::thread::sleep;
use std::time::Duration;
use std::time::Instant;
use std::cmp::min;
use std::cmp::max;

type Coord = (i32, i32);
type LiveSet = HashSet<Coord>;
const GENERATIONS: i32 = 1000;
const SHOW_WORK: bool = false;
enum Destiny {
    Live,
    Die,
    Ignored,
}
struct Change {
    destiny: Destiny,
    coord: Coord,
}
type Changes = Vec<Change>;
type Board = (LiveSet, Changes);
const HUMAN_WAIT: Duration = Duration::from_millis(1000/30);

fn apply_changes(board: &Board) -> LiveSet {
    let (live_set, changes) = board;
    let to_live: LiveSet = changes.iter()
	.filter(|c|match c.destiny { Destiny::Live => true, _ => false } )
	.map(|c|c.coord)
	.collect();
    let to_die: LiveSet = changes.iter()
	.filter(|c|match c.destiny { Destiny::Die => true, _ => false} )
	.map(|c|c.coord)
	.collect();
    let partial : LiveSet = live_set.difference(&to_die).cloned().collect();
    partial.union(&to_live).cloned().collect()
}

const OFFSETS : [i32; 3] = [-1, 0, 1];

fn eight(coord: &Coord) -> Vec<Coord> {
    let mut result = Vec::new();
    let (cx, cy) = coord;
    for x in OFFSETS.iter() {
	for y in OFFSETS.iter() {
	    if *x != 0 || *y != 0 {
		result.push((cx + *x, cy + *y));
	    }
	}
    }
    result
}

fn neighbors(changes: &Changes) -> LiveSet {
    let change_neighbors: LiveSet =
	changes.iter()
	.flat_map(|c|eight(&c.coord))
	.collect();
    change_neighbors
}

fn live(c: &Coord) -> Change {
    Change { destiny: Destiny::Live, coord: *c }
}

fn die(c: &Coord) -> Change {
    Change { destiny: Destiny::Die, coord: *c }
}

fn ignore(c: &Coord) -> Change {
    Change { destiny: Destiny::Ignored, coord: *c }
}

fn neighbor_count(live_set: &LiveSet, coord: &Coord) -> usize {
    eight(coord).iter().filter(|c|live_set.contains(c)).count()
}

fn change(live_set: &LiveSet, c: &Coord) -> Change {
    let count = neighbor_count(live_set, c);
    match count {
	2 => ignore(c),
	3 => if live_set.contains(c) { ignore(c) } else { live(c) },
	_ => if live_set.contains(c) { die(c) } else { ignore(c) },
    }
}

fn compute_changes(live_set: &LiveSet, affected: &LiveSet) -> Changes {
    let result : Changes =
	affected.iter()
	.map(|c|change(live_set, c))
	.filter(|c|match c.destiny { Destiny::Ignored => false, _ => true } )
	.collect();
    result
}

fn next(board: Board) -> Board {
    let new_set = apply_changes(&board);
    let affected = neighbors(&board.1);
    let updates = compute_changes(&new_set, &affected);
    (new_set, updates)
}

type BoundingBox = (Coord, Coord);
const MAX_MIN: Coord = (i32::MAX, i32::MIN);
const TINY_BOX: BoundingBox = (MAX_MIN, MAX_MIN);

fn bbox(live_set: &LiveSet) -> BoundingBox {
    if live_set.is_empty() {
	return ((0, 0), (1, 1));
    }
    let ((mut minx, mut maxx), (mut miny, mut maxy)) = TINY_BOX;
    for (x, y) in live_set.iter() {
	minx = min(minx, *x);
	miny = min(miny, *y);
	maxx = max(maxx, *x);
	maxy = max(maxy, *y);
    }
    return ((minx, miny), (maxx, maxy))
}

fn clear_screen() {
    print!("\x1b[2J");
    print!("\x1b[;H");
}

fn print_board(board: &Board) {
    clear_screen();
    let (live_set, _) = board;
    let ((minx, miny), (maxx, maxy)) = bbox(live_set);
    for y in (miny..=maxy).rev() {
	for x in minx..=maxx {
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
    let r_pentimino = [(0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)];
    let changes : Changes = r_pentimino.iter()
	.map(|c|Change {
	    destiny: Destiny::Live,
	    coord: *c,
	})
	.collect();
    let mut board = (HashSet::new(), changes);
    for _gen in 0..GENERATIONS {
	board = next(board);
	if SHOW_WORK {
	    print_board(&board);
	}
    }
    print!("{} generations per second\n",
	   f64::from(GENERATIONS) / now.elapsed().as_secs_f64());
}

fn main() {
    for _ in 0..5 {
	run();
    }
}
