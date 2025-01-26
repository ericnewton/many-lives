import std/[sets, sequtils, os, sugar, options, times]

type
  Coord = tuple
    x, y: int

proc coord(p : (int, int)): Coord =
  let (x, y) = p
  return (x: x, y: y)

type
  Change = tuple
    alive: bool
    coord: Coord

proc kill(coord: Coord): Change =
  return (alive: false, coord: coord)

proc live(coord: Coord): Change =
  return (alive: true, coord: coord)

type
  Board = tuple
    alive: HashSet[Coord]
    updates: seq[Change]

proc clearScreen() =
  # clear screen
  stdout.write "\e[2J"
  # move to top-left corner
  stdout.write "\e[;H"
  stdout.flushFile()

proc lowerLeft(a: Coord, b: Coord): Coord =
  return (min(a.x, b.x), min(a.y, b.y))

proc upperRight(a: Coord, b: Coord): Coord =
  return (max(a.x, b.x), max(a.y, b.y))

proc boundBox(board: Board): (Coord, Coord)  =
  let lst = board.alive.toSeq()
  if lst.len() == 0:
    return ((0, 0), (1, 1))
  let ll = foldl(lst, lowerLeft(a, b))
  let ur = foldl(lst, upperRight(a, b))
  return (ll, ur)

proc printBoard(board: Board) =
  let human_speed = int(1000 / 30)
  clearScreen()
  let (min, max) = boundBox(board)
  for y in countdown(max.y, min.y):
    for x in min.x .. max.x:
      if board.alive.contains((x, y)):
        stdout.write('@')
      else:
        stdout.write(' ')
    stdout.write('\n')
  stdout.flushFile()
  sleep(human_speed)

# apply the kill/resurection set to the live set
proc applyUpdates(alive : SomeSet[Coord], updates: seq[Change]): SomeSet[Coord] =
  let toLive = updates.filterIt(it.alive).mapIt(it.coord).toHashSet()
  let toDie = updates.filterIt(not it.alive).mapIt(it.coord).toHashSet()
  return (toLive + alive) - toDie

let OFFSETS* = collect(newSeq):
    for x in -1..1:
      for y in -1..1:
        if x != 0 or y != 0: (x, y)

iterator eight(coord: Coord) : Coord {.inline.} =
  for (xoff, yoff) in OFFSETS:
    yield (coord.x + xoff, coord.y + yoff)

iterator neighborsOfCoords(coords: seq[Coord]) : Coord {.inline.} =
  for coord in coords:
    for neighbor in eight(coord):
      yield neighbor

proc affected(changes: seq[Change]): SomeSet[Coord] =
  return changes.toSeq().mapIt(it.coord).neighborsOfCoords().toSeq().toHashSet()

# compute the state change for the next generation at a given coord
proc computeChange(alive: SomeSet[Coord], coord: Coord): Option[Change] =
  let liveCount = eight(coord).countIt(alive.contains(it))
  if liveCount == 2:
    return none(Change)
  if coord in alive:
    if liveCount != 3:
      return some(kill(coord))
  else:
    if liveCount == 3:
      return some(live(coord))
  return none(Change)

# get the set of changes to apply to the next generation for a set of points
proc computeChanges(alive: SomeSet[Coord], affected: seq[Coord]): SomeSet[Change] =
  return affected.mapIt(computeChange(alive, it)).filterIt(it.isSome).mapIt(it.get()).toHashSet()

# compute a new board from the old board
proc nextGeneration(board: Board): Board =
  let alive = applyUpdates(board.alive, board.updates)
  let affected = affected(board.updates)
  let updates = computeChanges(alive, affected.toSeq())
  return (alive, updates.toSeq())
  
proc start(alive: SomeSet[Coord]): Board =
  # turn on the start nodes
  let birth = alive.mapIt(live(it)).toHashSet()
  # mark the surrounding nodes as off for the complete affected set
  let death = (neighborsOfCoords(alive.toSeq()).toSeq().toHashSet() - alive).mapIt(kill(it)).toHashSet()
  let empty = initHashSet[Coord]()
  let updates = birth + death
  return (empty, updates.toSeq())

proc run1(board : Board, generations: int, showWork: bool) =
  if generations == 0:
    return
  let next = nextGeneration(board)
  if showWork:
    printBoard(next)
  run1(next, generations - 1, showWork)

proc main() =
  let r_pentomino = toHashSet([(0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)])
  let generations = 1000
  let showWork = false
  let times = (if showWork: 1 else: 5)
  for t in 1..times:
    let now = cpuTime()
    run1(start(r_pentomino), generations, showWork)
    let diff = cputime() - now;
    echo generations.float / diff, " generations / sec"

main()
