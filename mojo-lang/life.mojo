#! /usr/bin/env python3

from std.time import sleep, perf_counter_ns
from std.collections import Set

def clearScreen():
    # clear screen
    print("\033[2J", end='')
    # move to top-left corner
    print("\033[;H", end='')

def printBoard(liveSet : Set[Tuple[Int, Int]]) raises:
    var human_speed: Float64 = 1. / 30.
    clearScreen()
    for y in range(12, -12, -1):
        for x in range(-40, 40):
            if (x, y) in liveSet:
                print("@", end='')
            else:
                print(" ", end='')
        print()
    sleep(human_speed)


# compute a new liveSet from the old liveSet
def nextGeneration(liveSet: Set[Tuple[Int, Int]]) -> Set[Tuple[Int, Int]]:
    var OFFSETS = [(x, y) for x in [-1, 0, 1] for y in [-1, 0, 1] if x or y]
    var counts = Dict[Tuple[Int, Int], Int]()
    for x, y in liveSet:
        for x_offset, y_offset in OFFSETS:
            var key = (x + x_offset, y + y_offset)
            try:
                counts[key] += 1
            except:
                counts[key] = 1
    var result = Set[Tuple[Int, Int]]()
    for item in counts.items():
        var k = item.key
        var count = item.value
        if count == 3 or (count == 2 and k in liveSet):
            result.add(k)
    return result^

def main() raises:
    var PENTOMINO = Set([(0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)])
    var generations = 1000
    var showWork = False
    var times = 1 if showWork else 5
    for _ in range(0, times):
        var liveSet = PENTOMINO.copy()
        var now = perf_counter_ns()
        for _ in range(0, generations):
            if showWork:
                printBoard(liveSet)
            liveSet = nextGeneration(liveSet)
        var diff = perf_counter_ns() - now
        var per_sec = generations * 1_000_000_000 / diff
        print("{} generations / sec".format(per_sec))

