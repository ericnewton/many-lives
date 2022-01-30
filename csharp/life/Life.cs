using System;
using System.Collections.Generic;
// I tried IImmutableSet/ImmutableHash map and it was 3x slower!
// using System.Collections.Immutable;
using System.Linq;

namespace life
{
    struct Coord
    {
        public readonly int x;
        public readonly int y;
        public Coord(int x, int y)
        {
            this.x = x;
            this.y = y;
        }
    }
    enum Destiny { Live, Die }

    struct Change
    {
        public readonly Coord coord;
        public readonly Destiny destiny;
        public Change(Coord coord, Destiny destiny)
        {
            this.coord = coord;
            this.destiny = destiny;
        }
    }

    struct Box
    {
        public readonly Coord lowerLeft;
        public readonly Coord upperRight;
        public Box(Coord lowerLeft, Coord upperRight)
        {
            this.lowerLeft = lowerLeft;
            this.upperRight = upperRight;
        }
    }

    class Life
    {
        static readonly int GENERATIONS = 1000;
        static readonly bool SHOW_WORK = false;

        public static readonly Coord[] rPentomino = new Coord[] {
                new Coord(0, 0),
                new Coord(0, 1),
                new Coord(1, 1),
                new Coord(-1, 0),
                new Coord(0, -1)
                };

        static ISet<Coord> ApplyUpdates(
            ISet<Coord> liveSet,
            IEnumerable<Change> changes)
        {
            var toDie =
                from c in changes where c.destiny == Destiny.Die select c.coord
                ;
            var toLive =
                from c in changes where c.destiny == Destiny.Live select c.coord
                ;
            var result = new HashSet<Coord>(liveSet);
            result.ExceptWith(toDie);
            result.UnionWith(toLive);
            return result;
        }

        private static readonly Box tinyBox = new(
            new Coord(int.MaxValue, int.MaxValue),
            new Coord(int.MinValue, int.MinValue)
            );

        private static Box Enlarge(Box box, Coord c)
        {
            return new(
                new Coord(Math.Min(box.lowerLeft.x, c.x), Math.Min(box.lowerLeft.y, c.y)),
                new Coord(Math.Max(box.upperRight.x, c.x), Math.Max(box.upperRight.y, c.y))
                );
        }

        private static void PrintLiveSet(ISet<Coord> liveSet)
        {
            Console.Write("\x1b[2J\x1b[;H");
            if (liveSet.Count == 0)
            {
                return;
            }
            var boundingBox = liveSet.Aggregate(tinyBox, Enlarge);
            var ur = boundingBox.upperRight;
            var ll = boundingBox.lowerLeft;
            foreach (int y in Enumerable.Range(ll.y, ur.y - ll.y + 1).Reverse())
            {
                foreach (int x in Enumerable.Range(ll.x, ur.x - ll.x + 1))
                {
                    if (liveSet.Contains(new Coord(x, y)))
                    {
                        Console.Write("@");
                    }
                    else
                    {
                        Console.Write(" ");
                    }
                }
                Console.WriteLine("");
            }
            System.Threading.Thread.Sleep(1000 / 30);
        }

        private static readonly int[] offsets = { -1, 0, 1 };

        private static IEnumerable<Coord> Eight(Coord c)
        {
            var result = new List<Coord>(8);
            foreach (var y in offsets)
            {
                foreach (var x in offsets)
                {
                    if (x != 0 || y != 0)
                    {
                        result.Add(new Coord(c.x + x, c.y + y));
                    }
                }
            }
            return result;
        }

        private static ISet<Coord> ComputeNeighbors(IEnumerable<Change> changes)
        {
            return (
                from c in changes
                select Eight(c.coord)
            )
            .SelectMany(x => x)
            .ToHashSet();
        }

        private static int NeighborCount(ISet<Coord> liveSet, Coord n)
        {
            return (from c in Eight(n) where liveSet.Contains(c) select 1).Sum();
        }

        private static IEnumerable<Change> ComputeUpdates(ISet<Coord> liveSet, ISet<Coord> neighbors)
        {
            var result = new List<Change>(neighbors.Count);
            foreach (var n in neighbors)
            {
                switch (NeighborCount(liveSet, n))
                {
                    case 2:
                        break;
                    case 3:
                        if (!liveSet.Contains(n))
                        {
                            result.Add(new Change(n, Destiny.Live));
                        }
                        break;
                    default:
                        if (liveSet.Contains(n))
                        {
                            result.Add(new Change(n, Destiny.Die));
                        }
                        break;
                }
            }
            return result;
        }

        private static void Run()
        {
            var updates = from c in rPentomino
                          select new Change(c, Destiny.Live);
            ISet<Coord> liveSet = new HashSet<Coord>();

            foreach (int generation in Enumerable.Range(1, GENERATIONS))
            {
                liveSet = ApplyUpdates(liveSet, updates);
                if (SHOW_WORK)
                {
                    PrintLiveSet(liveSet);
                }
                var neighbors = ComputeNeighbors(updates);
                updates = ComputeUpdates(liveSet, neighbors);
            }
        }

        static void Main(string[] _)
        {
            if (SHOW_WORK)
            {
                Run();
            }
            else
            {
                foreach (int _unused in Enumerable.Range(0, 5))
                {
                    var start = DateTime.Now;
                    Run();
                    var stop = DateTime.Now;
                    var diffMillis = stop.Subtract(start).TotalMilliseconds;
                    Console.WriteLine(String.Format("{0} generations per sec", GENERATIONS * 1000 / diffMillis));
                }
            }
        }
    }
}
