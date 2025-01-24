package manylives;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class App2 {
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

	private static Coord p(int x, int y) {
		return new Coord(x, y);
	}

	private static final int[][] R_PENTOMINO_PAIRS = new int[][] { { 0, 0 }, { 0, 1 }, { 1, 1 }, { -1, 0 }, { 0, -1 } };
	private static final Set<Coord> R_PENTOMINO = Stream.of(R_PENTOMINO_PAIRS).map(pr -> p(pr[0], pr[1]))
			.collect(Collectors.toSet());
	private static final Character ESC = 27;
	private static final String CLEAR_SCREEN = ESC + "[2J";
	private static final String HOME_CURSOR = ESC + "[;H";

	private static void clearScreen() {
		System.out.print(CLEAR_SCREEN);
		System.out.print(HOME_CURSOR);
	}

	private static void printBoard(Set<Coord> liveSet) {
		for (int y = 12; y > -12; y--) {
			for (int x = -40; x < 40; x++) {
				if (liveSet.contains(p(x, y))) {
					System.out.print("@");
				} else {
					System.out.print(" ");
				}
			}
			System.out.println();
		}
	}

	private static AtomicInteger incr(Coord ignored, AtomicInteger i) {
		if (i == null) {
			return new AtomicInteger(1);
		} else {
			i.incrementAndGet();
		}
		return i;
	}

	// compute a new liveSet from the old liveSet
	private static Set<Coord> nextGeneration(Set<Coord> liveSet) {
		HashMap<Coord, AtomicInteger> counts = new HashMap<>(liveSet.size() * 8);
		for (Coord live : liveSet) {
			for (int x = -1; x <= 1; x++) {
				for (int y = -1; y <= 1; y++) {
					if (x != 0 || y != 0) {
						counts.compute(new Coord(live.x + x, live.y + y), App2::incr);
					}
				}
			}
		}
		Set<Coord> result = new HashSet<>(counts.size());
		for (Map.Entry<Coord, AtomicInteger> entry : counts.entrySet()) {
			int n = entry.getValue().intValue();
			if (n == 3 || (n == 2 && liveSet.contains(entry.getKey()))) {
				result.add(entry.getKey());
			}
		}
		return result;
	}

	public static void main(String[] args) throws InterruptedException {
		int generations = 1000;
		boolean showWork = args.length > 0;
		int times = 10;
		long humanAnimationSpeedMillis = 1000 / 30;
		for (int time = 0; time < times; time++) {
			Set<Coord> liveSet = R_PENTOMINO;
			long start = System.currentTimeMillis();
			for (int gen = 0; gen < generations; gen++) {
				liveSet = nextGeneration(liveSet);
				if (showWork) {
					clearScreen();
					printBoard(liveSet);
					Thread.sleep(humanAnimationSpeedMillis);
				}
			}
			long msecs = System.currentTimeMillis() - start;
			System.out.printf("%.2f generations / sec%n", generations / (msecs / 1000.0));
		}
	}
}
