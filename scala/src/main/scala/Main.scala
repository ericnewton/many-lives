private case class Position(x: Int, y: Int)
private type LiveSet = Set[Position]
private enum How { case Live, Die}
private case class Change(how : How, position : Position)
private type ChangeSet = IndexedSeq[Change]
private type Positions = IndexedSeq[Position]
private case class Board(live: LiveSet, updates: ChangeSet)

private def live(position: Position) : Change =
  return new Change(How.Live, position)

private def die(position: Position) : Change =
  return new Change(How.Die, position)

private val r_pentomino = IndexedSeq(
  (0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)
).map(x => new Position(x._1, x._2))

private def clearScreen() : Unit =
  val esc = 27
  // clear screen
  printf("%c[2J", esc)
  // move to top-left corner
  printf("%c[;H", esc)

private def boundBox(board : Board) : (Position, Position) =
  val lst = board.live
  if (lst.isEmpty)
    return (new Position(0, 0), new Position(1, 1))
  val xs = lst.map(coord => coord.x)
  val ys = lst.map(coord => coord.y)
  (new Position(xs.min, ys.min), new Position(xs.max, ys.max))

private def printBoard(board: Board) : Unit =
  val (min, max) = boundBox(board)
  for (y <- max.y to min.y by -1)
    for(x <- min.x to max.x)
      print(if (board.live(new Position(x, y))) "@" else " ")
    println()

// apply the kill/resurection set to the live set
private def applyUpdates(alive : LiveSet, updates : ChangeSet) : LiveSet =
  val kill = updates.filter(x => x.how == How.Die).map(x => x.position)
  val live = updates.filter(x => x.how == How.Live).map(x => x.position)
  alive ++ live -- kill

// generate the eight neighbor positions of a given position
private def eight(position : Position) : Positions =
  for (i <- -1 to 1; j <- -1 to 1 if (i != 0 || j != 0))
    yield new Position(position.x + i, position.y + j)

// generate the set of all affected neighbors for a ChangeSet
private def neighbors(changes : ChangeSet) : Positions =
  changes.map(c => c.position).flatMap(pos => eight(pos)).distinct

// compute the state change for the next generation at a given position
private def change(alive : LiveSet, pos : Position) : Option[Change] =
  val liveCount = eight(pos).filter(p => alive(p)).length
  if (liveCount == 2)
    return None
  if (alive(pos)) {
    if (liveCount != 3 && liveCount != 2)
      return Some(die(pos))
  } else {
    if (liveCount == 3)
      return Some(live(pos))
  }
  None

// get the set of changes to apply to the next generation for a set of points
private def computeChanges(alive : LiveSet, affected : Positions) : ChangeSet =
  affected.map(pos => change(alive, pos)).filter(x => x.isDefined).map(x => x.get)

// compute a new board from the old board
private def nextGeneration(board : Board) : Board =
  val alive = applyUpdates(board.live, board.updates)
  val affected = neighbors(board.updates)
  val updates = computeChanges(alive, affected)
  new Board(alive, updates)

@main def life: Unit =
  var board = new Board(Set(), r_pentomino.map(live))
  val generations = 1000
  val showWork = false
  val times = 5
  val humanAnimationSpeedMillis = 1000 / 30;
  for (time <- 0 to times)
    val start = System.currentTimeMillis()
    for (i <- 0 to generations)
      board = nextGeneration(board)
      if (showWork)
        clearScreen()
        printBoard(board)
        Thread.sleep(humanAnimationSpeedMillis)
    val msecs = System.currentTimeMillis() - start;
    printf("%.2f generations / sec\n", generations / (msecs / 1000.0))