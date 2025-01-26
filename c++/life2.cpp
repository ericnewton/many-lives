#include <iostream>
// #include <unordered_map>
#include "array_hash.h"
#include <thread>
#include <chrono>

using namespace std;

namespace life {

struct Cell {
  int x, y;
  bool operator==(const Cell & b) const {
    return x == b.x && y == b.y;
  }
  Cell() {}
  Cell(int x, int y) : x(x), y(y) {}
  Cell(const Cell & p) : x(p.x), y(p.y) {}
};

// for debugging
ostream & operator<<(ostream &ostr, const Cell & p) {
  ostr << "(" << p.x << ", " << p.y << ")";
  return ostr;
}

struct Hash {
  size_t operator()(const Cell &position) const {
    return position.x * 97 + position.y;
  }
};

  //typedef unordered_map<Cell, bool, Hash> CellSet;
typedef ah::ArrayHash<Cell, bool, Hash> CellSet;

void clearScreen() {
  // clear screen
  cout << char(27) << "[2J";
  // move to top-left corner
  cout << char(27) << "[;H";
}

void printCellSet(const CellSet & alive) {
  for (auto y = 12; y > -12; y--) {
    for (auto x = -40; x < 40; x++) {
      cout << (alive.count(Cell(x, y)) ? '@' : ' ');
    }
    cout << endl;
  }
}

const pair<int, int> p(int first, int second) {
  return pair<int, int>(first, second);
}
const pair<int, int> OFFSETS[] = {
  p(-1, 1),  p(0,  1), p(1,  1),
  p(-1, 0),            p(1,  0),
  p(-1, -1), p(0, -1), p(1, -1)
};

// compute a new liveSet from the old liveSet
unique_ptr<CellSet> nextGeneration(const CellSet & liveSet) {
  ah::ArrayHash<Cell, unsigned, Hash> counts(liveSet.size() * 8);
  //unordered_map<Cell, unsigned, Hash> counts(liveSet.size() * 8);
  for (auto cell : liveSet) {
    for (auto offsets : OFFSETS) {
      Cell offset(cell.first.x + offsets.first, cell.first.y + offsets.second);
      counts[offset]++;
    }
  }
  unique_ptr<CellSet> result(new CellSet(counts.size()));
  for (auto entry : counts) {
    if (entry.second == 3 || (entry.second == 2 && liveSet.count(entry.first) > 0)) {
      (*result)[entry.first] = true;
    }
  }
  return result;
}

const Cell c(int x, int y) { return Cell(x, y); }

} // namespace life

using namespace life;

int main(int argc, char **argv) {
  const Cell r_pentomino_array[] = {
    c(0, 0), c(0, 1), c(1, 1), c(-1, 0), c(0, -1)
  };
  CellSet r_pentomino(5);
  for (Cell c : r_pentomino_array) {
    r_pentomino[c] = true;
  }
  const auto generations = 1000;
  const auto showWork = argc > 1;
  const auto times = 5;
  const auto human_speed = chrono::milliseconds(1000 / 30);
  try {
    for (int time = 0; time < times; time++) {
      unique_ptr<CellSet> board(new CellSet(r_pentomino));
      auto start = std::chrono::system_clock::now();
      for(int i = 0; i < generations; i++) {
	if (showWork) {
	  clearScreen();
	  printCellSet(*board);
	  this_thread::sleep_for(human_speed);
	}
	board = nextGeneration(*board);
      }
      auto end = std::chrono::system_clock::now();
      auto diff_us = chrono::duration_cast<chrono::microseconds>(end - start);
      auto diff_s = diff_us.count() / 1000. / 1000.;
      cout << (generations / diff_s) << " generations / sec" << endl;
    }
  } catch (runtime_error & e) {
    cout << "Error: " << e.what() << endl;
  }
  return 0;
}
