import Data.Char (chr)
import Data.List (concat, intersperse)
import Control.Concurrent (threadDelay)
import qualified Data.Set as Set
import Debug.Trace

humanSpeed = 1 / 30.0
generations = 1000
data DestinyType = Live | Die | Ignore deriving (Show, Eq, Ord)

clearScreen = do
  -- clear the screen
  putStr (esc : "[2J")
  -- move the cursor to the "home" position
  putStr (esc : "[;H")
  where
    esc = chr(27)

cell liveSet x y =
  if (Set.member (x, y) liveSet) then '@' else ' '

row liveSet y minx maxx =
  map (\x -> cell liveSet x y) [minx .. maxx]

asString board =
  concat (intersperse "\n"
          (map (\y -> row liveSet y minx maxx) [maxy, maxy - 1 .. miny]))
  where
    (liveSet, updates) = board
    xs = Set.map (\(x, y) -> x) liveSet
    ys = Set.map (\(x, y) -> y) liveSet
    minx = Set.findMin xs
    maxx = Set.findMax xs
    miny = Set.findMin ys
    maxy = Set.findMax ys

printBoard board = do
  clearScreen
  putStrLn (asString board)
  threadDelay (round (1000000 * humanSpeed))

applyUpdates liveSet updates =
  Set.difference (Set.union liveSet toLive) toDie
  where
    toLive = Set.fromList [pos | (Live, pos) <- updates]
    toDie = Set.fromList [pos | (Die, pos) <- updates]

neighbors pos =
  [(posx + x, posy + y)| x <- [-1 .. 1], y <- [-1 .. 1], x /= 0 || y /= 0]
  where
    (posx, posy) = pos

considerSet positions =
  Set.fromList (concat (map neighbors positions))

-- rules of life
change pos 2 _     = (Ignore, pos)
change pos 3 False = (Live,   pos)
change pos 3 True  = (Ignore, pos)
change pos _ True  = (Die,    pos)
change pos _ _     = (Ignore, pos)

computeChange liveSet pos =
  change pos neighborCount isAlive
  where
    neighborCount = length [True|n <- (neighbors pos), Set.member n liveSet]
    isAlive = Set.member pos liveSet

computeUpdates liveSet updates =
  [(how, pos)|(how, pos) <- (Set.toList newUpdates), how /= Ignore]
  where
    changed = [pos|(how, pos) <- updates]
    newUpdates = Set.map (\ pos -> computeChange liveSet pos) (considerSet changed)

next board =
  (newSet, newUpdates)
  where
    (liveSet, updates) = board
    newSet = applyUpdates liveSet updates
    newUpdates = computeUpdates newSet updates

printGeneration 0 board = do
  -- do something with the last board to force evaluation
  -- otherwise nothing gets computed and we can't benchmark
  putStrLn (show (length updates))
  where
    (lifeSet, updates) = board

printGeneration n board =
  do
    -- printBoard board
    printGeneration (n - 1) (next board)

run n = do
  printGeneration n start
  where
    r_pentomino = [(0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)]
    update = map (\ pos -> (Live, pos)) r_pentomino
    -- empty Sets don't "show", so throw in a value to keep it
    -- from being empty and we can get some debugging done
    -- since this is the first value in the initial generation, it's
    -- basically ignored
    liveSet = (Set.fromList [head r_pentomino])
    start = (liveSet, update)
    
main = do
  run generations
  run generations
  run generations
  run generations
  run generations
