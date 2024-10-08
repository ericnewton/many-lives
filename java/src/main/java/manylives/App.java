package manylives;

import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Sets;
import org.apache.commons.lang3.tuple.Pair;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class App {
    enum How { Die, Live }
    private static class Coord {
        public final int x;
        public final int y;
        public Coord(int x, int y) {
            this.x = x;
            this.y = y;
        }

        @Override
        public String toString() {
            return String.format("{x=%d, y=%d}", x, y);
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) {
                return true;
            }
            if (!(o instanceof Coord)) {
                return false;
            }
            Coord position = (Coord) o;
            return x == position.x && y == position.y;
        }

        @Override
        public int hashCode() {
            return Objects.hash(x, y);
        }
    }

    private static class Change {
        public final How how;
        public final Coord position;
        public Change(How how, Coord position) {
            this.how = how;
            this.position = position;
        }
    }

    private static class Board {
        final ImmutableSet<Coord> alive;
        final Collection<Change> changes;
        public Board(ImmutableSet<Coord>  alive, Collection<Change> changes) {
            this.alive = alive;
            this.changes = changes;
        }
    }
    private static Coord p(int x, int y) {
        return new Coord(x, y);
    }
    private static final int[][] R_PENTOMINO_PAIRS = new int[][]{
            {0, 0}, {0, 1}, {1, 1}, {-1, 0}, {0, -1}
    };
    private static final ImmutableSet<Change> R_PENTOMINO =
            Stream.of(R_PENTOMINO_PAIRS)
                    .map(pr -> new Change(How.Live, p(pr[0], pr[1])))
                    .collect(ImmutableSet.toImmutableSet());
    private static final Character ESC = 27;
    private static final String CLEAR_SCREEN = ESC + "[2J";
    private static final String HOME_CURSOR = ESC + "[;H";
    private static void clearScreen() {
        System.out.print(CLEAR_SCREEN);
        System.out.print(HOME_CURSOR);
    }

    private static Pair<Coord, Coord> boundBox(Board board) {
        ImmutableSet<Coord> lst = board.alive;
        if (lst.isEmpty()) {
            return Pair.of(p(0, 0), p(1, 1));
        }
        int minx = lst.stream().mapToInt(p -> p.x).min().getAsInt();
        int maxx = lst.stream().mapToInt(p -> p.x).max().getAsInt();
        int miny = lst.stream().mapToInt(p -> p.y).min().getAsInt();
        int maxy = lst.stream().mapToInt(p -> p.y).max().getAsInt();
        return Pair.of(p(minx, miny), p(maxx, maxy));
    }

    private static void printBoard(Board board) {
        Pair<Coord, Coord> bbox = boundBox(board);
        for (int y = bbox.getRight().y; y >= bbox.getLeft().y; y--) {
            for (int x = bbox.getLeft().x; x <= bbox.getRight().x; x++) {
                if (board.alive.contains(p(x, y))) {
                    System.out.print("@");
                } else {
                    System.out.print(" ");
                }
            }
            System.out.println();
        }
    }

    // apply the kill/resurrection set to the live set
    private static ImmutableSet<Coord> applyUpdates(ImmutableSet<Coord> alive,
						    Collection<Change> updates) {
        Set<Coord> result = Sets.newHashSet(alive);
        updates.forEach(c -> {
            if (c.how == How.Die) {
                result.remove(c.position);
            } else {
                result.add(c.position);
            }
        });
        return ImmutableSet.copyOf(result);
    }

    // generate the eight neighbor positions of a given position
    private static ImmutableSet<Coord> eight(Coord position) {
        ImmutableSet.Builder<Coord> result = ImmutableSet.builder();
        for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
                if (i != 0 || j != 0) {
                    result.add(p(position.x + i, position.y + j));
                }
            }
        }
        return result.build();
    }

    // generate the set of all affected neighbors for a ChangeSet
    private static ImmutableSet<Coord> neighbors(Collection<Change> changes) {
       return changes.stream()
                .map(c -> c.position)
                .flatMap(pos -> eight(pos).stream())
                .collect(ImmutableSet.toImmutableSet());
    }

    // compute the state change for the next generation at a given position
    private static Change change(ImmutableSet<Coord> alive, Coord pos) {
        final int liveCount = (int) eight(pos).stream().filter(alive::contains).count();
        if (liveCount == 2) {
            return null;
        }
        if (alive.contains(pos)) {
            if (liveCount != 3) {
                return new Change(How.Die, pos);
            }
        } else {
            if (liveCount == 3) {
                return new Change(How.Live, pos);
            }
        }
        return null;
    }

    // get the set of changes to apply to the next generation for a set of points
    private static Collection<Change> computeChanges(ImmutableSet<Coord> alive,
						     ImmutableSet<Coord> affected) {
        return affected.parallelStream()
	            .map(pos -> change(alive, pos))
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }

    // compute a new board from the old board
    private static Board nextGeneration(Board board) {
        ImmutableSet<Coord> alive = applyUpdates(board.alive, board.changes);
        ImmutableSet<Coord> affected = neighbors(board.changes);
        Collection<Change> updates = computeChanges(alive, affected);
        return new Board(alive, updates);
    }

    public static void main( String[] args ) throws InterruptedException {
        int generations = 1000;
        boolean showWork = false;
        int times = 5;
        long humanAnimationSpeedMillis = 1000 / 30;
        for (int time = 0; time < times; time++) {
	    Board board = new Board(ImmutableSet.of(), R_PENTOMINO);
            long start = System.currentTimeMillis();
            for (int gen = 0; gen < generations; gen++) {
                board = nextGeneration(board);
                if (showWork) {
                    clearScreen();
                    printBoard(board);
                    Thread.sleep(humanAnimationSpeedMillis);
                }
            }
            long msecs = System.currentTimeMillis() - start;
            System.out.printf("%.2f generations / sec%n", generations / (msecs / 1000.0));
        }
    }
}
