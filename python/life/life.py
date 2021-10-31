#! /usr/bin/env python3
import sys
import time
from collections import namedtuple

Board = namedtuple('Board', ['alive', 'updates'])

r_pentomino = [
    (0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)
]

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
    min, max = boundBox(board)
    minx, miny = min
    maxx, maxy = max
    for y in range(maxy, miny - 1, -1):
        for x in range(minx, maxx + 1):
            print("@" if (x, y) in board.alive else " ", end='')
        print()

# apply the kill/resurection set to the live set
def applyUpdates(alive, updates):
    kill = [p for c, p in updates if not c]
    live = [p for c, p in updates if c]
    return alive.union(live).difference(kill)

OFFSETS = [(x, y) for x in (-1, 0, 1) for y in (-1, 0, 1) if x or y]

# generate the eight neighbor positions of a given position
def eight(position):
    x, y = position
    for xoff, yoff in OFFSETS:
        yield (x + xoff, y + yoff)

# generate the set of all affected neighbors for a ChangeSet
def neighbors(changes):
    return set([neighbor for change, pos in changes for neighbor in eight(pos)])

# compute the state change for the next generation at a given position
def change(alive, pos):
    liveCount = len([True for n in eight(pos) if n in alive])
    if liveCount == 2:
        return None
    if pos in alive:
        if liveCount != 3:
            return (False, pos)
    else:
        if liveCount == 3:
            return (True, pos)
    return None

# get the set of changes to apply to the next generation for a set of points
def computeChanges(alive, affected):
  changes = [change(alive, pos) for pos in affected]
  return [e for e in changes if e]

# compute a new board from the old board
def nextGeneration(board):
  alive = applyUpdates(board.alive, board.updates)
  affected = neighbors(board.updates)
  updates = computeChanges(alive, affected)
  return Board(alive, updates)


def main():
    board = Board(set(), [(True, p) for p in r_pentomino])
    generations = 1000
    showWork = False
    times = 5
    human_speed = 1/30.
    for _ in range(0, times):
        start = time.time()
        for i in range(0, generations):
          board = nextGeneration(board)
          if showWork:
            clearScreen()
            printBoard(board)
            time.sleep(human_speed)
        diff = time.time() - start;
        print(f"{generations / diff:.2f} generations / sec")

if __name__ == '__main__':
    main()
