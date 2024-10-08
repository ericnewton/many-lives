#! /usr/bin/env python3
import sys
import time
from collections import namedtuple

# add some typing... but also makes it slower :(

Live = True
Die = False
Position = namedtuple('Position', ['x', 'y'])
Change = namedtuple('Change', ['how', 'position'])
Board = namedtuple('Board', ['alive', 'updates'])

# jython's `print` is not a function, so this function just allows us
# to used this file with python3 and jython (we don't really need to print
# anything)
def p(*args, **kw):
    print(args)

def clearScreen():
    # clear screen
    p("\033[2J", end='')
    # move to top-left corner
    p("\033[;H", end='')

def boundBox(board):
    lst = board.alive
    if not lst:
        return (Position(0,0), Position(1,1))
    xs = set([p.x for p in lst])
    ys = set([p.y for p in lst])
    return (Position(min(xs), min(ys)), Position(max(xs), max(ys)))

def printBoard(board):
    min, max = boundBox(board)
    for y in range(max.y, min.y - 1, -1):
        for x in range(min.x, max.x + 1):
            p("@" if Position(x, y) in board.alive else " ", end='')
        p()

# apply the kill/resurection set to the live set
def applyUpdates(alive, updates):
    kill = [u.position for u in updates if u.how == Die]
    live = [u.position for u in updates if u.how == Live]
    return alive.union(live).difference(kill)

OFFSETS = [(x, y) for x in (-1, 0, 1) for y in (-1, 0, 1) if x or y]

# generate the eight neighbor positions of a given position
def eight(position):
    for xoff, yoff in OFFSETS:
        yield Position(position.x + xoff, position.y + yoff)

# generate the affected cells of a ChangeSet
def affected(changes):
    return set([neighbor for change, pos in changes for neighbor in eight(pos)])

# compute the state change for the next generation at a given position
def change(alive, pos):
    liveCount = len([True for n in eight(pos) if n in alive])
    if liveCount == 2:
        return None
    if pos in alive:
        if liveCount != 3:
            return Change(Die, pos)
    else:
        if liveCount == 3:
            return Change(Live, pos)
    return None

# get the set of changes to apply to the next generation for a set of points
def computeChanges(alive, affected):
  changes = [change(alive, pos) for pos in affected]
  # strip None's from changes
  return [e for e in changes if e]

# compute a new board from the old board
def nextGeneration(board):
  alive = applyUpdates(board.alive, board.updates)
  affectedSet = affected(board.updates)
  updates = computeChanges(alive, affectedSet)
  return Board(alive, updates)

def start(live):
    live = {Position(x, y) for x, y in live}
    birth = [Change(Live, p) for p in live]
    death = [Change(Die, n) for p in live for n in eight(p) if n not in live]
    return Board(set(), birth + death)

def main(pattern):
    from rle import rle
    board = start(rle(pattern))
    generations = 1000
    showWork = False
    times = 5
    human_speed = 1/30.
    for _ in range(0, times):
        now = time.time()
        for i in range(0, generations):
          board = nextGeneration(board)
          if showWork:
            clearScreen()
            printBoard(board)
            time.sleep(human_speed)
        diff = time.time() - now
        print("%2f generations / sec" % (generations/diff,))

if __name__ == '__main__':
    with open(sys.argv[1]) as fp:
        main(fp.read())
