defmodule Life do

  def applyUpdates(liveSet, updates) do
      live = MapSet.new(Keyword.get_values(updates, :live))
      die = MapSet.new(Keyword.get_values(updates, :die))
      MapSet.difference(MapSet.union(liveSet, live), die)
  end

  def eight(pos) do
    {posx, posy} = pos
    nine = for x <- -1..1, y <- -1..1, do: if x != 0 or y != 0, do: {posx + x, posy + y}
    Enum.filter(nine, &!is_nil(&1))
  end

  def neighbors(changes) do
    MapSet.new(Enum.flat_map(Keyword.values(changes), &eight(&1)))
  end

  def neighborCount(liveSet, pos) do
    Enum.count(Enum.filter(eight(pos), &alive?(liveSet, &1)))
  end

  def rules(liveSet, pos) do
    count = neighborCount(liveSet, pos)
    case count do
      2 -> nil
      3 -> if !alive?(liveSet, pos), do: {:live, pos}
      _ -> if alive?(liveSet, pos), do: {:die, pos}
    end
  end

  def computeChanges(liveSet, affected) do
    Enum.filter(Enum.map(affected, &rules(liveSet, &1)), &!is_nil(&1))
  end

  def boundingBox(liveSet) do
    {minx, maxx} = Enum.min_max(Enum.map(liveSet, fn ({x,_}) -> x end))
    {miny, maxy} = Enum.min_max(Enum.map(liveSet, fn ({_,y}) -> y end))
    {{minx, miny}, {maxx, maxy}}
  end

  def alive?(liveSet, pos) do
    MapSet.member?(liveSet, pos)
  end

  def printRow(liveSet, y, minx, maxx) do
    IO.puts(
      for x <- minx..maxx, do: if alive?(liveSet, {x,y}), do: '@', else: ' '
    )
  end

  def clearScreen() do
    IO.write("\e[2J")
    IO.write("\e[;H")
  end

  def printBoard(liveSet) do
    clearScreen()
    {{minx, miny}, {maxx, maxy}} = boundingBox(liveSet)
    for y <- maxy..miny, do: printRow(liveSet, y, minx, maxx)
    :timer.sleep(div(1000, 30))
  end
  
  def generation(n, showWork, liveSet, updates) do
    if n > 0 do
      newSet = applyUpdates(liveSet, updates)
      if showWork do
	printBoard(newSet)
      end
      affected = neighbors(updates)
      newChanges = computeChanges(newSet, affected)
      generation(n - 1, showWork, newSet, newChanges)
    end
  end

  def life(n, showWork) do
    start = :os.system_time(:millisecond)
    r_pentomino = Enum.map(
      [{0, 0}, {0, 1}, {1, 1}, {-1, 0}, {0, -1}],
      & {:live, &1}
    )
    generation(n, showWork, MapSet.new(), r_pentomino)
    diff = :os.system_time(:millisecond) - start
    IO.puts(to_string(n / (diff / 1000.0)) <> " generations per sec")
  end
end

if false do
  Life.life(300, true)
else
  for _ <- 1..5 do
      Life.life(1000, false)
  end
end
