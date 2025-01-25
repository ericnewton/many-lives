#include <iostream>
#include <unordered_set>
#include <unordered_map>
#include <thread>
#include <chrono>

using namespace std;

namespace life {

struct Cell {
  int x, y;
  bool operator==(const Cell & b) const {
    return x == b.x && y == b.y;
  }
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
typedef unordered_set<Cell, Hash> CellSet;

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

const pair<int, int> OFFSETS[] = {
  {-1, 1},  {0,  1}, {1,  1},
  {-1, 0},           {1,  0},
  {-1, -1}, {0, -1}, {1, -1}
};

// compute a new board from the old board
unique_ptr<CellSet> nextGeneration(const CellSet & board) {
  unordered_map<Cell, unsigned, Hash> counts(board.size() * 2);
  for (auto cell : board) {
    for (auto offsets : OFFSETS) {
      Cell neighbor(cell.x + offsets.first, cell.y + offsets.second);
      counts[neighbor]++;
    }
  }
  unique_ptr<CellSet> result(new CellSet(counts.size()));
  for (auto entry : counts) {
    if (entry.second == 3 || (entry.second == 2 && board.find(entry.first) != board.end())) {
      result->insert(entry.first);
    }
  }
  return result;
}

} // namespace life

using namespace life;

int main(int argc, char **argv) {
  const CellSet r_pentomino = {
    {0, 0}, {0, 1}, {1, 1}, {-1, 0}, {0, -1}
  };
  const auto generations = 1000;
  const auto showWork = argc > 1;
  const auto times = 5;
  const auto human_speed = chrono::milliseconds(1000 / 30);
  for (int time = 0; time < times; time++) {
    unique_ptr<const CellSet> board(new CellSet(r_pentomino));
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
  return 0;
}
