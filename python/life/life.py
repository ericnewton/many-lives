#! /usr/bin/env python3
import sys
import time
from collections import namedtuple

Board = namedtuple('Board', ['alive', 'updates'])

def clearScreen():
    # clear screen
    print("\033[2J", end='')
    # move to top-left corner
    print("\033[;H", end='')

def boundBox(board):
    lst = board.alive
    if not lst:
        return ((0,0), (1,1))
    xs = set([x for x, y in lst])
    ys = set([y for x, y in lst])
    return ((min(xs), min(ys)), (max(xs), max(ys)))

def printBoard(board):
    human_speed = 1/30.
    clearScreen()
    min, max = boundBox(board)
    minx, miny = min
    maxx, maxy = max
    for y in range(maxy, miny - 1, -1):
        for x in range(minx, maxx + 1):
            print("@" if (x, y) in board.alive else " ", end='')
        print()
    time.sleep(human_speed)

# apply the kill/resurection set to the live set
def applyUpdates(alive, updates):
    kill = [p for c, p in updates if not c]
    live = [p for c, p in updates if c]
    return alive.union(live).difference(kill)

OFFSETS = [(x, y) for x in (-1, 0, 1) for y in (-1, 0, 1) if x or y]

# generate the eight neighbor coordinates of a given coordinate
def eight(coord):
    x, y = coord
    for xoff, yoff in OFFSETS:
        yield (x + xoff, y + yoff)

def nine(coord):
    for c in eight(coord):
        yield(c)
    yield coord
        
# generate the set of all affected neighbors for a ChangeSet
def neighbors(changes):
    return set([neighbor for change, pos in changes for neighbor in eight(pos)])

def affected(changes):
    return set([neighbor for change, pos in changes for neighbor in nine(pos)])

# compute the state change for the next generation at a given coord
def computeChange(alive, coord):
    liveCount = len([True for n in eight(coord) if n in alive])
    if liveCount == 2:
        return None
    if coord in alive:
        if liveCount != 3:
            return (False, coord)
    else:
        if liveCount == 3:
            return (True, coord)
    return None

# get the set of changes to apply to the next generation for a set of points
def computeChanges(alive, affected):
  changes = [computeChange(alive, coord) for coord in affected]
  return [e for e in changes if e]

# compute a new board from the old board
def nextGeneration(board):
  alive = applyUpdates(board.alive, board.updates)
  affected_ = affected(board.updates)
  updates = computeChanges(alive, affected_)
  return Board(alive, updates)

def main(pattern):
    from rle import rle
    board = Board(set(), [(True, p) for p in rle(pattern)])
    generations = 1000
    showWork = False
    times = 1 if showWork else 5
    for _ in range(0, times):
        start = time.time()
        for i in range(0, generations):
            board = nextGeneration(board)
            if showWork:
                printBoard(board)
        diff = time.time() - start;
        print(f"{generations / diff:.2f} generations / sec")

if __name__ == '__main__':
    import sys
    with open(sys.argv[1]) as fp:
        main(fp.read())
