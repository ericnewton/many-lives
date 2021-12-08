import Data.Char (chr)
import Data.List (concat, intersperse)
import Control.Concurrent (threadDelay)
import qualified Data.Set as Set

humanSpeed = 1 / 30.0
generations = 1000
data State = Alive | Dead
data DestinyType = Live | Die | Ignore deriving (Show, Eq, Ord)
data Coord = Coord {coord_x :: Int, coord_y :: Int } deriving (Show, Eq, Ord)
type LiveSet = Set.Set(Coord)
type Change = (DestinyType, Coord)
type Board = (LiveSet, [Change])

clearScreen :: IO ()
clearScreen = do
  -- clear the screen
  putStr (esc : "[2J")
  -- move the cursor to the "home" position
  putStr (esc : "[;H")
  where
    esc = chr(27)

cell :: LiveSet -> Coord -> Char
cell liveSet coord =
  if (Set.member coord liveSet) then '@' else ' '

row :: LiveSet -> Int -> Int -> Int -> [Char]
row liveSet minx maxx y =
  map (\x -> cell liveSet (Coord x y)) [minx .. maxx]


expandBox :: ((Int, Int), (Int, Int)) -> Coord -> ((Int, Int), (Int, Int))
expandBox box coord =
  ((min minx x, min miny y), (max maxx x, max maxy y))
  where
    ((minx, miny), (maxx, maxy)) = box
    (x, y) = (coord_x coord, coord_y coord)

bbox :: Foldable t => t (Coord) -> ((Int, Int), (Int, Int))
bbox lst =
  foldl expandBox tinybox lst
  where
    minint = minBound::Int
    maxint = maxBound::Int
    tinybox = ((maxint, maxint), (minint, minint))

asString :: Board -> [Char]
asString board =
  concat (intersperse "\n"
          (map (row liveSet minx maxx) [maxy, maxy - 1 .. miny]))
  where
    (liveSet, updates) = board
    ((minx, miny), (maxx, maxy)) = bbox liveSet

printBoard :: Board -> IO ()
printBoard board = do
  clearScreen
  putStrLn (asString board)
  threadDelay (round (1000000 * humanSpeed))

applyUpdates :: LiveSet -> [Change] -> LiveSet
applyUpdates liveSet updates =
  Set.union (Set.difference liveSet toDie) toLive
  where
    toLive = Set.fromList [pos | (Live, pos) <- updates]
    toDie = Set.fromList [pos | (Die, pos) <- updates]

neighbors :: Coord -> [Coord]
neighbors pos =
  [Coord (posx + x) (posy + y)| x <- [-1 .. 1], y <- [-1 .. 1], x /= 0 || y /= 0]
  where
    (posx, posy) = (coord_x pos, coord_y pos)

considerSet :: [Coord] -> Set.Set(Coord)
considerSet positions =
  Set.fromList (concat (map neighbors positions))

-- rules of life
change :: Int -> State -> DestinyType
change 2 _     = Ignore
change 3 Dead  = Live
change 3 Alive = Ignore
change _ Alive = Die
change _ _     = Ignore

computeChange :: LiveSet -> Coord -> Change
computeChange liveSet pos =
  (how, pos)
  where
    neighborCount = length [True|n <- (neighbors pos), Set.member n liveSet]
    state = if Set.member pos liveSet then Alive else Dead
    how = change neighborCount state

computeUpdates :: LiveSet -> [Change] -> [Change]
computeUpdates liveSet updates =
  [(how, pos)|(how, pos) <- (Set.toList newUpdates), how /= Ignore]
  where
    changed = [pos|(how, pos) <- updates]
    newUpdates = Set.map (computeChange liveSet) (considerSet changed)

next :: Board -> Board
next board =
  (newSet, newUpdates)
  where
    (liveSet, updates) = board
    newSet = applyUpdates liveSet updates
    newUpdates = computeUpdates newSet updates

printGeneration :: Int -> Board -> IO ()
printGeneration 0 board = do
  -- do something with the last board to force evaluation
  -- otherwise nothing gets computed and we can't benchmark
  putStrLn (show (length updates))
  where
    (lifeSet, updates) = board

printGeneration n board =
  do
    -- for standard game-of-life display, uncomment this line:
    -- printBoard board
    printGeneration (n - 1) (next board)

run :: Int -> IO ()
run n = do
  printGeneration n start
  where
    r_pentomino = [(0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)]
    update = map (\ (x, y) -> (Live, Coord x y)) r_pentomino
    liveSet = (Set.fromList [])
    start = (liveSet, update)

main :: IO ()
main = do
  run generations
  run generations
  run generations
  run generations
  run generations
