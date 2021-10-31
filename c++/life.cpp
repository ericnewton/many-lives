#include <iostream>
#include <set>
#include <unordered_set>
#include <vector>
#include <utility>
#include <thread>
#include <chrono>

using namespace std;

/*
 * The goal is to use immutable data structures.  However, to support
 *
 * board = nextGeneration(board)
 *
 * The type Board has to support operator=, which means all the types in
 * Board need an operator=, which means i can just slap const on everything.
 * So I've written accessors that don't let you do anything to the types but
 * read them.
 *
 * Let the copious boilerplate production begin...
 */

class Position {
private:
  // I forgot the member data and member methods share the same
  // namespace. So, name members with awkward "m_" prefixes.
  int m_x, m_y;
public:
  // if we use set, which is ordered
  bool operator<(const Position & b) const {
    if (m_x == b.m_x) {
      return m_y < b.m_y;
    }
    return m_x < b.m_x;
  }
  // if we use unordered set
  bool operator==(const Position & b) const {
    return m_x == b.m_x && m_y == b.m_y;
  }
  Position(int x, int y) : m_x(x), m_y(y) {}
  Position(const Position & p) : m_x(p.m_x), m_y(p.m_y) {}
  int x() const {
    return m_x;
  }
  int y() const {
    return m_y;
  }
};

struct Hash {
  size_t operator()(const Position &position) const {
    return position.x() * 65521 + position.y();
  }
};

// for debugging
ostream & operator<<(ostream &ostr, const Position & p) {
  ostr << "(" << p.x() << ", " << p.y() << ")";
  return ostr;
}

enum How { Live, Die, None };

// I forgot c++ doesn't provide a conversion from enum to string
ostream & operator<<(ostream &ostr, How how) {
  switch (how) {
  case Live:
    cout << "Live";
    break;
  case Die:
    cout << "Die";
    break;
  case None:
    cout << "None";
    break;
  }
  return ostr;
}

class Change {
private:
  How m_how;
  Position m_position;
public:
  Change(How how, const Position & pos) : m_how(how), m_position(pos) {}
  How how() const { return m_how; }
  const Position & position() const {
    return m_position;
  }
};
// in other languages we use Option(al) or None, or nil, etc.  Make our own placeholder:
const Change DoNothing(None, Position(0, 0));
// more debugging
ostream & operator<<(ostream &ostr, const Change & c) {
  ostr << "how=" << c.how() << ", position=" << c.position();
  return ostr;
}

typedef unordered_set<Position, Hash> Positions;
// typedef set<Position> Positions;

class Board {
private:
  Positions m_alive;
  vector<Change> m_updates;
public:
  Board(const Positions & alive,
	const vector<Change> & updates)
    : m_alive(alive),
      m_updates(updates)
  {
  }
  const Positions & alive() const {
    return m_alive;
  }
  const vector<Change> & updates() const {
    return m_updates;
  }
};

// debugging
ostream & operator<<(ostream &ostr, const Board & b) {
  ostr << "alive=";
  for (auto each : b.alive()) {
    ostr << each << ", ";
  }
  ostr << "updates=";
  for (auto each : b.updates()) {
    ostr << each << ", ";
  }
  return ostr;
 }

Position p(int x, int y) {
  return Position(x, y);
}
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
  const Positions lst = board.alive();
  if (lst.empty()) {
    return make_pair(Position(0,0), Position(1,1));
  }
  // for the love of turing why isn't this easier?
  // (didn't want to create a mutable Position)
  auto i = lst.begin();
  int minx = i->x();
  int miny = i->y();
  int maxx = minx;
  int maxy = miny;
  i++;
  for (; i != lst.end(); i++) {
    minx = min(minx, i->x());
    maxx = max(maxx, i->x());
    miny = min(miny, i->y());
    maxy = max(maxy, i->y());
  }
  return make_pair(Position(minx, miny), Position(maxx, maxy));;
}

void printBoard(const Board & board) {
  auto pr = boundBox(board);
  const Position & min = pr.first;
  const Position & max = pr.second;
  for (int y = max.y(); y >= min.y(); y--) {
    for(int x = min.x(); x <= max.x(); x++) {
      char symbol = ' ';
      if (board.alive().count(Position(x, y))) {
	symbol = '@';
      }
      cout << symbol;
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
    if (change.how() == Die) {
      result.erase(change.position());
    } else if (change.how() == Live) {
      result.insert(change.position());
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

// generate the eight neighbor positions of a given position
vector<Position> eight(const Position & position) {
  vector<Position> result;
  for (int i = 0; i < sizeof(OFFSETS)/sizeof(OFFSETS[0]); i++) {
    result.push_back(Position(position.x() + OFFSETS[i][0],
			      position.y() + OFFSETS[i][1]));
  }
  return result;
}

// generate the set of all affected neighbors for a ChangeSet
Positions neighbors(const vector<Change> & changes) {
  Positions result;
  for (auto & change : changes) {
    for (auto & pos : eight(change.position())) {
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
    if (c.how() != None) {
      result.push_back(c);
    }
  }
  return result;
}

// compute a new board from the old board
Board nextGeneration(const Board & board) {
  // this came out nicer than I was expecting
  auto alive = applyUpdates(board.alive(), board.updates());
  auto affected = neighbors(board.updates());
  auto updates = computeChanges(alive, affected);
  return Board(alive, updates);
}

int main(int argc, char **argv) {
  vector<Change> start;
  for (int i = 0; i < sizeof(r_pentomino) / sizeof(r_pentomino[0]); i++) {
    start.push_back(Change(Live, r_pentomino[i]));
  }
  Board board(Positions(), start);
  const auto generations = 1000;
  const auto showWork = false;
  const auto times = 5;
  const auto human_speed = chrono::milliseconds(1000 / 30);
  for (int time = 0; time < times; time++) {
    auto start = std::chrono::system_clock::now();
    for(int i = 0; i < generations; i++) {
      board = nextGeneration(board);
      if (showWork) {
	clearScreen();
	printBoard(board);
	this_thread::sleep_for(human_speed);
      }
    }
    auto end = std::chrono::system_clock::now();
    auto diff_ms = chrono::duration_cast<chrono::milliseconds>(end - start);
    auto diff_s = diff_ms.count() / 1000.;
    cout << (generations / diff_s) << " " << diff_ms.count() << " generations / sec" << endl;
  }
  return 0;
}
