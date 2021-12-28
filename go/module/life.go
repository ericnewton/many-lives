package main

import "fmt"
import "math"
import "time"
import "github.com/dropbox/godropbox/container/set"

const showWork = false;

type Destiny int
const (
	Live Destiny = iota
	Die
)

type Coord struct {
	x int
	y int
}

type BoundingBox struct {
	lowerLeft Coord
	upperRight Coord
}

type Change struct {
	destiny Destiny
	pos Coord
}

type Board struct {
	liveSet set.Set
	updates []Change
}

func applyChanges(board Board) set.Set {
	toLive := set.NewSet()
	toDie := set.NewSet()
	for _, change := range board.updates {
		if change.destiny == Live {
			toLive.Add(change.pos)
		} else {
			toDie.Add(change.pos)
		}
	}
	return set.Union(set.Subtract(board.liveSet, toDie), toLive)
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

func getBoundingBox(liveSet set.Set) BoundingBox {
	if (liveSet.Len() == 0) {
		return BoundingBox{Coord{0, 0}, Coord{1, 1}}
	}
	minx := math.MaxInt32
	maxx := math.MinInt32
	miny := math.MaxInt32
	maxy := math.MinInt32
	for v := range liveSet.Iter() {
		p := v.(Coord)
		minx = min(minx, p.x)
		maxx = max(maxx, p.x)
		miny = min(miny, p.y)
		maxy = max(maxy, p.y)
	}
	return BoundingBox{Coord{minx, miny}, Coord{maxx, maxy}}
}

func clearScreen() {
	fmt.Print("\033[2J\033[;H")
}

func printBoard(liveSet set.Set) {
	bbox := getBoundingBox(liveSet)
	for y := bbox.upperRight.y; y >= bbox.lowerLeft.y; y-- {
		for x := bbox.lowerLeft.x; x <= bbox.upperRight.x; x++ {
			if liveSet.Contains(Coord{x, y}) {
				fmt.Print("@")
			} else {
				fmt.Print(" ")
			}
		}
		fmt.Println()
	}
}

func eight(pos Coord) []Coord {
	var result = make([]Coord, 8);
	var i = 0;
	for x := -1; x <= 1; x++ {
		for y := -1; y <= 1; y++ {
			if x != 0 || y != 0 {
				result[i] = Coord{pos.x + x, pos.y + y};
				i = i + 1;
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
		pos := a.(Coord);
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
	r_pentomino := [...]Coord{
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
		for i := 0; i < 5; i++ {
			life()
		}
	}
}
