#include <iostream>
//#include <unordered_map>
//#include <google/dense_hash_map>
//#include <google/sparse_hash_map>
#include "array_hash.h"
#include <climits>
#include <thread>
#include <chrono>

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

static const Cell EMPTY_KEY(INT_MAX, INT_MAX);

// for debugging
std::ostream & operator<<(std::ostream &ostr, const Cell & p) {
  ostr << "(" << p.x << ", " << p.y << ")";
  return ostr;
}

struct Hash {
  size_t operator()(const Cell &position) const {
    return position.x * 97 + position.y;
  }
};

  //typedef unordered_map<Cell, bool, Hash> CellSet;
  //typedef unordered_map<Cell, unsigned, Hash> CellCount;
  typedef ah::ArrayHash<Cell, bool, Hash> CellSet;
  typedef ah::ArrayHash<Cell, unsigned, Hash> CellCount;
  //typedef google::sparse_hash_map<Cell, bool, Hash> CellSet;
  //typedef google::sparse_hash_map<Cell, unsigned, Hash> CellCount;

void clearScreen() {
  // clear screen
  std::cout << char(27) << "[2J";
  // move to top-left corner
  std::cout << char(27) << "[;H";
}

void printCellSet(const CellSet & alive) {
  for (auto y = 12; y > -12; y--) {
    for (auto x = -40; x < 40; x++) {
      std::cout << (alive.count(Cell(x, y)) ? '@' : ' ');
    }
    std::cout << std::endl;
  }
}

const std::pair<int, int> p(int first, int second) {
  return std::pair<int, int>(first, second);
}
const std::pair<int, int> OFFSETS[] = {
  p(-1, 1),  p(0,  1), p(1,  1),
  p(-1, 0),            p(1,  0),
  p(-1, -1), p(0, -1), p(1, -1)
};

// compute a new liveSet from the old liveSet
std::unique_ptr<CellSet> nextGeneration(const CellSet & liveSet) {
  CellCount counts(liveSet.size() * 8);
  // counts.set_empty_key(EMPTY_KEY);
  //unordered_map<Cell, unsigned, Hash> counts(liveSet.size() * 8);
  for (auto cell : liveSet) {
    for (auto offsets : OFFSETS) {
      Cell offset(cell.first.x + offsets.first, cell.first.y + offsets.second);
      counts[offset]++;
    }
  }
  std::unique_ptr<CellSet> result(new CellSet(counts.size()));
  //result->set_empty_key(EMPTY_KEY);
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
  //r_pentomino.set_empty_key(EMPTY_KEY);
  for (Cell c : r_pentomino_array) {
    r_pentomino[c] = true;
  }
  const auto generations = 1000;
  const auto showWork = argc > 1;
  const auto times = 5;
  const auto human_speed = std::chrono::milliseconds(1000 / 30);
  
  for (unsigned time = 0; time < times; time++) {
    std::unique_ptr<CellSet> board(new CellSet(r_pentomino));
    auto start = std::chrono::system_clock::now();
    for(unsigned i = 0; i < generations; i++) {
      if (showWork) {
	clearScreen();
	printCellSet(*board);
	std::this_thread::sleep_for(human_speed);
      }
      board = nextGeneration(*board);
    }
    auto end = std::chrono::system_clock::now();
    auto diff_us = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    auto diff_s = diff_us.count() / 1000. / 1000.;
    std::cout << (generations / diff_s) << " generations / sec" << std::endl;
  }
  return 0;
}
