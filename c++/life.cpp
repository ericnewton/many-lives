#include <iostream>
#include <set>
#include <unordered_set>
#include <vector>
#include <algorithm>
#include <utility>
#include <thread>
#include <chrono>

using namespace std;

namespace life {

struct Position {
  int x, y;
  // if we put Position in a set, define an order:
  bool operator<(const Position & b) const {
    if (x == b.x) {
      return y < b.y;
    }
    return x < b.x;
  }
  // if we use unordered_set, define equality
  bool operator==(const Position & b) const {
    return x == b.x && y == b.y;
  }
  Position(int x, int y) : x(x), y(y) {}
  Position(const Position & p) : x(p.x), y(p.y) {}
};
struct CompareX {
  bool operator()(const Position & a, const Position & b) const { return a.x < b.x; }
};
struct CompareY {
  bool operator()(const Position & a, const Position & b) const { return a.y < b.y; }
};

struct Hash {
  size_t operator()(const Position &position) const {
    return position.x * 65521 + position.y;
  }
};

// for debugging
ostream & operator<<(ostream &ostr, const Position & p) {
  ostr << "(" << p.x << ", " << p.y << ")";
  return ostr;
}

enum How { Live, Die, Unchanged };

ostream & operator<<(ostream &ostr, How how) {
  switch (how) {
  case Live:
    cout << "Live";
    break;
  case Die:
    cout << "Die";
    break;
  case Unchanged:
    cout << "Unchanged";
    break;
  }
  return ostr;
}

struct Change {
  How how;
  Position position;
  Change(How how, const Position & pos) : how(how), position(pos) {}
};

const Change DoNothing(Unchanged, Position(0, 0));

// more debugging
ostream & operator<<(ostream &ostr, const Change & c) {
  ostr << "how=" << c.how << ", position=" << c.position;
  return ostr;
}

// Hashed sets are about 12% faster for me
typedef unordered_set<Position, Hash> Positions;
//typedef set<Position> Positions;

struct Board {
  const Positions alive;
  const vector<Change> updates;

  Board(const Positions & alive,
	const vector<Change> & updates)
    : alive(alive),
      updates(updates)
  {
  }
};

// debugging
ostream & operator<<(ostream &ostr, const Board & b) {
  ostr << "alive=";
  string sep = "";
  for (auto each : b.alive) {
    ostr << sep << each;
    sep = ", ";
  }
  ostr << "updates=";
  sep = "";
  for (auto each : b.updates) {
    ostr << sep << each;
    sep = ", ";
  }
  return ostr;
 }

Position p(int x, int y) { return Position(x, y); }
const Position r_pentomino[] = {
  p(0, 0), p(0, 1), p(1, 1), p(-1, 0), p(0, -1)
};

void clearScreen() {
  // clear screen
  cout << char(27) << "[2J";
  // move to top-left corner
  cout << char(27) << "[;H";
}

pair<Position, Position> boundBox(const Board & board) {
  const Positions & lst = board.alive;
  if (lst.empty()) {
    return make_pair(Position(0,0), Position(1,1));
  }
  auto mmx = minmax_element(lst.begin(), lst.end(), CompareX());
  auto mmy = minmax_element(lst.begin(), lst.end(), CompareY());
  return make_pair(Position(mmx.first->x, mmy.first->y),
		   Position(mmx.second->x, mmy.second->y));
}

void printBoard(const Board & board) {
  auto bb = boundBox(board);
  auto min = bb.first;
  auto max = bb.second;
  for (auto y = max.y; y >= min.y; y--) {
    for(auto x = min.x; x <= max.x; x++) {
      cout << (board.alive.count(Position(x, y)) ? '@' : ' ');
    }
    cout << endl;
  }
}

// apply the Die/Live changes to the live set
Positions applyUpdates(const Positions & alive,
			   const vector<Change> & updates) {
  // use the same cheat in Java, but it's much harder to not
  // do it this way in c++
  Positions result(alive);
  for (auto & change : updates) {
    if (change.how == Die) {
      result.erase(change.position);
    } else if (change.how == Live) {
      result.insert(change.position);
    }
  }
  return result;
}

// harder to type, but easier to understand I think:
const int OFFSETS[][2] = {
  {-1, 1},  {0,  1}, {1,  1},
  {-1, 0},           {1,  0},
  {-1, -1}, {0, -1}, {1, -1}
};
const size_t OFFSET_COUNT = sizeof(OFFSETS)/sizeof(OFFSETS[0]);

// generate the eight neighbor positions of a given position
vector<Position> eight(const Position & position) {
  vector<Position> result;
  result.reserve(OFFSET_COUNT);
  for (size_t i = 0; i < OFFSET_COUNT; i++) {
    result.push_back(Position(position.x + OFFSETS[i][0],
			      position.y + OFFSETS[i][1]));
  }
  return result;
}

// generate the set of all affected neighbors for a ChangeSet
Positions neighbors(const vector<Change> & changes) {
  Positions result;
  result.reserve(changes.size() * 8);
  for (auto & change : changes) {
    for (auto & pos : eight(change.position)) {
      result.insert(pos);
    }
  }
  return result;
}

// compute the state change for the next generation at a given position
Change change(const Positions & alive, const Position & pos) {
  int liveCount = 0;
  for (auto & n : eight(pos)) {
    liveCount += alive.count(n);
  }
  if (liveCount == 2) {
    return DoNothing;
  }
  if (alive.count(pos)) {
    if (liveCount != 3) {
      return Change(Die, pos);
    }
  } else {
    if (liveCount == 3) {
      return Change(Live, pos);
    }
  }
  return DoNothing;
}

// get the set of changes to apply to the next generation for a set of points
vector<Change> computeChanges(const Positions & alive,
			      const Positions & affected) {
  // again, cheating with a local mutable type
  vector<Change> result;
  for (auto & pos : affected) {
    Change c = change(alive, pos);
    if (c.how != Unchanged) {
      result.push_back(c);
    }
  }
  return result;
}

// compute a new board from the old board
unique_ptr<Board> nextGeneration(const Board & board) {
  // this came out nicer than I was expecting
  auto alive = applyUpdates(board.alive, board.updates);
  auto affected = neighbors(board.updates);
  auto updates = computeChanges(alive, affected);
  return unique_ptr<Board>(new Board(alive, updates));
}

} // namespace life

using namespace life;

int main(int argc, char **argv) {
  vector<Change> start;
  for (size_t i = 0; i < sizeof(r_pentomino) / sizeof(r_pentomino[0]); i++) {
    start.push_back(Change(Live, r_pentomino[i]));
  }
  unique_ptr<const Board> board(new Board(Positions(), start));
  const auto generations = 1000;
  const auto showWork = false;
  const auto times = 5;
  const auto human_speed = chrono::milliseconds(1000 / 30);
  for (int time = 0; time < times; time++) {
    auto start = std::chrono::system_clock::now();
    for(int i = 0; i < generations; i++) {
      board = nextGeneration(*board);
      if (showWork) {
	clearScreen();
	printBoard(*board);
	this_thread::sleep_for(human_speed);
      }
    }
    auto end = std::chrono::system_clock::now();
    auto diff_us = chrono::duration_cast<chrono::microseconds>(end - start);
    auto diff_s = diff_us.count() / 1000. / 1000.;
    cout << (generations / diff_s) << " generations / sec" << endl;
  }
  return 0;
}
