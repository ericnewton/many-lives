import Destiny.*
import kotlinx.collections.immutable.*
import java.lang.Integer.max
import java.lang.Integer.min
import java.util.concurrent.TimeUnit.MILLISECONDS
import kotlin.system.measureTimeMillis
import kotlin.collections.mutableListOf

const val GENERATIONS = 1000
const val SHOW_WORK = false
val ESC : Char = Char(27)

data class Coord(val x: Int, val y: Int)
enum class Destiny {
    LIVE, DIE, IGNORE
}
data class Change(val coord: Coord, val destiny: Destiny)
typealias LiveSet = PersistentSet<Coord>
typealias Changes = PersistentSet<Change>
data class Board(val alive: LiveSet, val updates: Changes)
data class Box(val lowerLeft : Coord, val upperRight : Coord)

private fun enlargeBox(b : Box, coord: Coord): Box {
    return Box(
        Coord(min(b.lowerLeft.x, coord.x), min(b.lowerLeft.y, coord.y)),
        Coord(max(b.upperRight.x, coord.x), max(b.upperRight.y, coord.y))
    )
}

private fun boundingBox(board: Board) : Box {
    val mn = Int.MIN_VALUE
    val mx = Int.MAX_VALUE
    val smallBox = Box(Coord(mx, mx), Coord(mn, mn))
    return board.alive.fold(smallBox) { box, coord -> enlargeBox(box, coord) }
}

private fun printBoard(board: Board) {
    val box = boundingBox(board)
    print("${ESC}[2J")
    print("${ESC}[;H")
    for (y in box.upperRight.y downTo box.lowerLeft.y) {
        for (x in box.lowerLeft.x .. box.upperRight.x) {
            print(if (board.alive.contains(Coord(x, y))) '@' else ' ')
        }
        println()
    }
    MILLISECONDS.sleep(1000 / 30L)
}

private fun eight() : ImmutableList<Coord> {
    val result = mutableListOf<Coord>()
    for (x in -1..1) {
        for (y in -1..1) {
            if (x != 0 || y != 0) {
                result.add(Coord(x, y))
            }
        }
    }
    return result.toImmutableList()
}
private val eight: List<Coord> = eight()

private fun neighbors(coord: Coord) : LiveSet {
    return eight.map { c -> Coord(coord.x + c.x, coord.y + c.y)} .toPersistentHashSet()
}

private fun computeNeighbors(changes : Changes): LiveSet {
    return changes.map { c -> c.coord } .flatMap { c -> neighbors(c) } .toPersistentHashSet()
}

private fun countNeighbors(coord : Coord, alive : LiveSet) : Int {
    return eight.count { c -> alive.contains(Coord(c.x + coord.x, c.y + coord.y)) }
}

private fun computeChange(coord : Coord, alive : LiveSet) : Change {
    return when (countNeighbors(coord, alive)) {
        2 -> Change(coord, IGNORE)
        3 -> Change(coord, if (alive.contains(coord)) IGNORE else LIVE)
        else -> Change(coord, if (alive.contains(coord)) DIE else IGNORE)
    }
}

private fun computeChanges(alive: LiveSet, neighbors: LiveSet): Changes {
    return neighbors.map { c -> computeChange(c, alive) }.filter { c -> c.destiny != IGNORE }.toPersistentHashSet()
}

private fun applyUpdates(board: Board): Board {
    val toLive = board.updates.filter {it.destiny == LIVE }.map {it.coord}.toPersistentHashSet()
    val toDie = board.updates.filter { it.destiny == DIE }.map {it.coord }.toPersistentHashSet()
    val alive = board.alive.minus(toDie).plus(toLive).toPersistentHashSet()
    val changeNeighbors = computeNeighbors(board.updates)
    val changes = computeChanges(alive, changeNeighbors)
    return Board(alive, changes)
}

private fun run() {
    val rPentomino = setOf(
        Coord(0, 0),
        Coord(0, 1),
        Coord(1, 1),
        Coord(-1, 0),
        Coord(0, -1)
    )
    val updates = rPentomino.map { Change(it, LIVE) } .toPersistentHashSet()
    var board = Board(persistentSetOf(), updates)
    val millis = measureTimeMillis {
        (1..GENERATIONS).forEach { _ ->
            board = applyUpdates(board)
            if (SHOW_WORK) {
                printBoard(board)
            }
        }
    }
    val rate = GENERATIONS * 1000.0 / millis
    println("$rate generations / sec")
}

fun main() {
    if (SHOW_WORK) {
        run()
    } else {
        for (i in 1..5) {
            run()
        }
    }
}