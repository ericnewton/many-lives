import Foundation

let SHOW_WORK = false;
let GENERATIONS = 1000;

struct Coord : Hashable {
    var x = 0
    var y = 0

    static func == (lhs: Coord, rhs: Coord) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y;
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
}
enum Destiny { case live, die }
struct Change : Hashable {
    var coord: Coord;
    var destiny: Destiny;
    
    static func == (lhs: Change, rhs: Change) -> Bool {
        return lhs.coord == rhs.coord && lhs.destiny == rhs.destiny;
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(coord)
        hasher.combine(destiny)
    }
}
struct BoundingBox {
    let lowerLeft : Coord;
    let upperRight : Coord;
}
let TINYBOX = BoundingBox(lowerLeft: Coord(x: Int.max, y: Int.max),
                          upperRight: Coord(x: Int.min, y: Int.min));


func applyUpdates(_ liveSet: Set<Coord>, _ updates: Set<Change>) -> Set<Coord> {
    let toLive = updates.filter { $0.destiny == .live } .map { $0.coord };
    let toDie = updates.filter { $0.destiny == .die } .map { $0.coord };
    return liveSet.subtracting(toDie).union(toLive);
}

func expandBox(_ box: BoundingBox, _ coord: Coord) -> BoundingBox {
    let lowerLeft = box.lowerLeft;
    let upperRight = box.upperRight;
    return BoundingBox(lowerLeft: Coord(x: min(coord.x, lowerLeft.x),
                                        y: min(coord.y, lowerLeft.y)),
                       upperRight: Coord(x: max(coord.x, upperRight.x),
                                         y: max(coord.y, upperRight.y)));
}

func printBoard(_ liveSet: Set<Coord>) {
    print("\u{1b}[2J\u{1b}[;H", terminator: "")
    let bbox = liveSet.reduce(TINYBOX, expandBox);
    for y in stride(from: bbox.upperRight.y, to: bbox.lowerLeft.y - 1, by: -1) {
        for x in bbox.lowerLeft.x ... bbox.upperRight.x {
            let coord = Coord(x: x, y: y)
            if liveSet.contains(coord) {
                print("@", terminator: "")
            } else {
                print(" ", terminator: "")
            }
        }
        print()
    }
    Thread.sleep(forTimeInterval: 1/30.0)
}

let neighborOffsets = [
  (-1, -1), (-1, 0), (-1, 1),
  ( 0, -1),          ( 0, 1),
  ( 1, -1), ( 1, 0), ( 1, 1)
]

func eight(_ coord: Coord) -> Set<Coord> {
    return Set(neighborOffsets.map { Coord(x: coord.x + $0.0,
                                           y: coord.y + $0.1) })
}

func computeNeighbors(_ changes: Set<Change>) -> Set<Coord> {
    return Set(changes.flatMap { eight($0.coord) })
}

func countNeighbors(_ liveSet: Set<Coord>, _ coord: Coord) -> Int {
    return eight(coord).filter { liveSet.contains($0) } .count;
}

func computeChanges(_ liveSet: Set<Coord>, _ neighbors: Set<Coord>) -> Set<Change> {
    var result : Set<Change> = [];
    for coord in neighbors {
        let n = countNeighbors(liveSet, coord)
        if (n != 2) {
            if (n == 3) {
                if (!liveSet.contains(coord)) {
                    result.insert(Change(coord: coord, destiny: .live))
                }
            } else {
                if (liveSet.contains(coord)) {
                    result.insert(Change(coord: coord, destiny: .die))
                }
            }
        }
    }
    return result;
}

func now() -> TimeInterval {
    return NSDate().timeIntervalSince1970;
}

func run() {
    let start = now()
    let rPentomino = [(0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)]
    var liveSet: Set<Coord> = [];
    var updates = Set(rPentomino.map{
        Change(coord: Coord(x: $0.0, y: $0.1), destiny: .live)
                      })
    for _ in 1...GENERATIONS {
        liveSet = applyUpdates(liveSet, updates)
        if (SHOW_WORK) {
            printBoard(liveSet);
        }
        let neighbors = computeNeighbors(updates)
        updates = computeChanges(liveSet, neighbors)
    }
    let diff = now() - start;
    print(String(format: "%.2f generations per second", Double(GENERATIONS) / diff))
}

func main() {
    if (SHOW_WORK) {
        run()
    } else {
        for _ in 1...5 {
            run()
        }
    }
}

main()
