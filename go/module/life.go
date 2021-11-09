package main

import "fmt"
import "math"
import "time"
import "github.com/dropbox/godropbox/container/set"

const showWork = false;

type How int
const (
	Live How = iota
	Die
)

type Pos struct {
	x int
	y int
}

type MinMax struct {
	min Pos
	max Pos
}

type Change struct {
	how How
	pos Pos
}

type Board struct {
	liveSet set.Set
	updates []Change
}

func applyChanges(board Board) set.Set {
	toLive := set.NewSet()
	toDie := set.NewSet()
	for _, change := range board.updates {
		if change.how == Live {
			toLive.Add(change.pos)
		} else {
			toDie.Add(change.pos)
		}
	}
	return set.Subtract(set.Union(board.liveSet, toLive), toDie)
}

func min(a int, b int) int {
	if a < b {
		return a;
	}
	return b;
}

func max(a int, b int) int {
	if a > b {
		return a;
	}
	return b;
}

func getBoundingBox(liveSet set.Set) MinMax {
	if (liveSet.Len() == 0) {
		return MinMax{Pos{0, 0}, Pos{1, 1}}
	}
	minx := math.MaxInt32
	maxx := math.MinInt32
	miny := math.MaxInt32
	maxy := math.MinInt32
	for v := range liveSet.Iter() {
		p := v.(Pos);
		minx = min(minx, p.x)
		maxx = max(maxx, p.x)
		miny = min(miny, p.y)
		maxy = max(maxy, p.y)
	}
	return MinMax{Pos{minx, miny}, Pos{maxx, maxy}}
}

func clearScreen() {
	fmt.Print("\033[2J\033[;H")
}

func printBoard(liveSet set.Set) {
	bbox := getBoundingBox(liveSet)
	for y := bbox.max.y; y >= bbox.min.y; y-- {
		for x := bbox.min.x; x <= bbox.max.x; x++ {
			if liveSet.Contains(Pos{x, y}) {
				fmt.Print("@")
			} else {
				fmt.Print(" ")
			}
		}
		fmt.Println();
	}
}

func eight(pos Pos) []Pos {
	var result []Pos;
	for x := -1; x <= 1; x++ {
		for y := -1; y <= 1; y++ {
			if x != 0 || y != 0 {
				result = append(result,	Pos{pos.x + x, pos.y + y})
			}
		}
	}
	return result
}

func neighbors(changes[] Change) set.Set {
	s := set.NewSet();
	for _, c := range changes {
		for _, p := range eight(c.pos) {
			s.Add(p);
		}
	}
	return s;
}

func computeChanges(liveSet set.Set, affected set.Set) []Change {
	var result []Change;
	for a := range affected.Iter() {
		pos := a.(Pos);
		count := 0
		for _, n := range eight(pos) {
			if liveSet.Contains(n) {
				count++;
			}
		}
		if count != 2 {
			alive := liveSet.Contains(pos);
			if !alive && count == 3 {
				result = append(result, Change{Live, pos})
			}
			if alive && count != 3 {
				result = append(result, Change{Die, pos})
			}
		}
	}
	return result;
}

func next(board Board) Board {
	newLiveSet := applyChanges(board)
	if showWork {
		clearScreen()
		printBoard(newLiveSet)
		time.Sleep(1000 / 30 * time.Millisecond)
	}
	affected := neighbors(board.updates)
	updates := computeChanges(newLiveSet, affected)
	return Board{newLiveSet, updates}
}

func life() {
	start := time.Now()
	const generations = 1000;
	r_pentomino := [...]Pos{
		{0, 0}, {0, 1}, {1, 1}, {-1, 0}, {0, -1},
	};
	r_changes := []Change{}
	for _, pos := range r_pentomino {
		r_changes = append(r_changes, Change{Live, pos})
	}
	empty := set.NewSet()
	board := Board{empty, r_changes};
	for i := 0; i < generations; i++ {
		board = next(board)
	}
	duration := time.Since(start)
	fmt.Println(generations * 1000 / duration.Milliseconds(), "generations /sec")
}

func main() {
	if showWork {
		life()
	} else {
		life()
		life()
		life()
		life()
		life()
	}
		
}
