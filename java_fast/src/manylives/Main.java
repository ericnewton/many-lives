package manylives;

import java.util.Arrays;

public class Main {

  static final int GENERATIONS = 1000;
  static final boolean SHOW_WORK = false;

  static final int coord_hash(int x, int y) {
    return (x * 191 + y) & 0xffff;
  }

  static final int CAPACITY = 2047;
  static final short UNSET = -1;

  static final class XYV {
    public final short values[] = new short[CAPACITY * 3];

    final void clear() {
      Arrays.fill(values, UNSET);
    }

    final short getX(int offset) {
      return values[offset * 3];
    }

    final short getY(int offset) {
      return values[offset * 3 + 1];
    }

    private final short getValue(int offset) {
      return values[offset * 3 + 2];
    }

    private final void setSlot(int offset, short x, short y, short v) {
      values[offset * 3] = x;
      values[offset * 3 + 1] = y;
      values[offset * 3 + 2] = v;
    }

    private final void incrementValue(int offset) {
      values[offset * 3 + 2]++;
    }

    final boolean isEmpty(int offset) {
      return getValue(offset) == UNSET;
    }

    private final boolean slotEquals(int offset, short x, short y) {
      return getX(offset) == x && getY(offset) == y;
    }

    private final int find(short x, short y) {
      int hash = coord_hash(x, y);
      int index = hash % CAPACITY;
      for (int i = index; i < CAPACITY; i++) {
        if (isEmpty(i)) {
          return i;
        }
        if (slotEquals(i, x, y)) {
          return i;
        }
      }
      for (int i = 0; i < index; i++) {
        if (isEmpty(i)) {
          return i;
        }
        if (slotEquals(i, x, y)) {
          return i;
        }
      }
      return -1;
    }

    final boolean increment(short x, short y) {
      int index = find(x, y);
      if (index < 0) {
        return false;
      }
      if (isEmpty(index)) {
        setSlot(index, x, y, (short) 0);
      }
      incrementValue(index);
      return true;
    }

    final int get(short x, short y) {
      int index = find(x, y);
      if (index < 0) {
        return 0;
      }
      if (isEmpty(index)) {
        return 0;
      }
      return getValue(index);
    }

    XYV() {
      clear();
    }
  };

  static final int HUMAN_WAIT_TIME_MS = 1000 / 30;

  static final void print_board(XYV live_map) {
    // clear screen, move cursor to upper-left corner
    System.out.printf("%c[2J;%c[;H", 27, 27);
    for (short y = 12; y > -12; y--) {
      for (short x = -40; x < 40; x++) {
        char c = ' ';
        if (live_map.get(x, y) > 0) {
          c = '@';
        }
        System.out.printf("%c", c);
      }
      System.out.println();
    }
    try {
      Thread.sleep(HUMAN_WAIT_TIME_MS);
    } catch (InterruptedException e) {
      throw new RuntimeException(e);
    }
  }

  static final boolean count_neighbors(XYV live_set, XYV counts) {
    for (int i = 0; i < CAPACITY; i++) {
      if (live_set.isEmpty(i)) {
        continue;
      }
      final short x = live_set.getX(i);
      final short y = live_set.getY(i);
      for (short offset_x = -1; offset_x <= 1; offset_x++) {
        for (short offset_y = -1; offset_y <= 1; offset_y++) {
          if (offset_x == 0 && offset_y == 0) {
            continue;
          }
          if (!counts.increment((short) (x + offset_x), (short) (y + offset_y))) {
            return false;
          }
        }
      }
    }
    return true;
  }

  static final boolean next_generation(XYV live_set, XYV counts, XYV result) {
    counts.clear();
    result.clear();
    if (!count_neighbors(live_set, counts)) {
      return false;
    }
    for (int i = 0; i < CAPACITY; i++) {
      if (counts.isEmpty(i)) {
        continue;
      }
      int value = counts.getValue(i);
      if (value == 3 || (value == 2 && live_set.get(counts.getX(i), counts.getY(i)) != 0)) {
        if (!result.increment(counts.getX(i), counts.getY(i))) {
          return false;
        }
      }
    }
    return true;
  }

  static final int run() {
    final short r_pentomino[][] = { { 0, 0 }, { 0, 1 }, { 1, 1 }, { -1, 0 }, { 0, -1 } };
    final XYV counts = new XYV();
    XYV live_set = new XYV();
    XYV next = new XYV();
    for (int i = 0; i < r_pentomino.length; i++) {
      if (!live_set.increment(r_pentomino[i][0], r_pentomino[i][1])) {
        return -1;
      }
    }
    for (int generation = 0; generation < GENERATIONS; generation++) {
      if (SHOW_WORK) {
        print_board(live_set);
      }
      if (!next_generation(live_set, counts, next)) {
        return -1;
      }
      final XYV tmp = live_set;
      live_set = next;
      next = tmp;
    }
    return 0;
  }

  public static void main(String[] args) {
    if (SHOW_WORK) {
      if (run() < 0) {
        System.err.printf("an error occurred");
        System.exit(1);
      }
    } else {
      for (int i = 0; i < 5; i++) {
        long start = System.nanoTime();
        if (run() < 0) {
          System.err.println("an error occurred");
          System.exit(1);
        }
        long end = System.nanoTime();
        long diff = end - start;
        System.out.printf("%d generations per second\n", (int) (GENERATIONS * 1e9 / diff));
      }
    }
  }
}
