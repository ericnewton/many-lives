require "set"

showWork = false
generations = 1000

Change = Struct.new(:how, :pos)

def applyUpdates(liveSet, updates)
  toLive = updates.filter_map{|c| c.pos if c.how == 'live'}
  toDie = updates.filter_map{|c| c.pos if c.how == 'die'}
  (liveSet | toLive) - toDie
end

def boundingBox(liveSet)
  xs = liveSet.map{|p| p[0]}
  ys = liveSet.map{|p| p[1]}
  [[xs.min, ys.min], [xs.max, ys.max]]
end

def printBoard(liveSet)
  bbox = boundingBox(liveSet)
  min = bbox[0]
  max = bbox[1]
  # clear the screaen
  print "\e[2J"
  # move to top-left corner
  print "\e[;H"
  print ""
  for y in max[1].downto(min[1]) do
    for x in (min[0] .. max[0]) do
      if liveSet.member? [x,y]
        print "@"
      else
        print " "
      end
    end
    puts ""
  end
  sleep 1/30.0
end

def eight(pos)
  (-1..1).flat_map{
    |x| (-1..1).filter_map{
      |y| [pos[0] + x, pos[1] + y] if x != 0 or y != 0
    }
  }
end

def computeAffected(updates)
  Set.new(updates.flat_map{|change| eight(change.pos)})
end

def neighborCount(liveSet, pos)
  eight(pos).filter_map{|n| 1 if liveSet.member? n}.sum
end

def computeChange(liveSet, pos, count)
  if count == 2
    return nil
  end
  alive = liveSet.member? pos
  if count == 3
    if !alive
      return Change.new('live', pos)
    end
  else
      if alive
        return Change.new('die', pos)
      end
  end
  nil
end

def computeChanges(liveSet, affected)
  affected.map{
    |pos|
    computeChange(liveSet, pos, neighborCount(liveSet, pos))
  }.select{|c| not c.nil?}
end

def generation(showWork, n, liveSet, updates)
  if n > 0
    newSet = applyUpdates(liveSet, updates)
    if showWork
      printBoard newSet
    end
    affected = computeAffected(updates)
    newChanges = computeChanges(newSet, affected)
    generation(showWork, n - 1, newSet, newChanges)
  end
end


def run(initialChanges, showWork, generations)
  start = Time.now
  generation(showWork, generations, Set.new, initialChanges)
  diff = Time.now - start
  puts "%.2f generations / sec" % (1000 / diff)
end

r_pentomino = [
  [0, 0], [0, 1], [1, 1], [-1, 0], [0, -1]
].map{ |pos| Change.new('live', pos)}
  
if showWork
  run(r_pentomino, showWork, generations)
else
  for i in 1..5
    run(r_pentomino, showWork, generations)
  end
end
