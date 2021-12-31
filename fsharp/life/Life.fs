open Printf
open System

let generations = 1000;;
let show_work = false;;

type coord = {x : int; y : int};;
type destiny = Live | Die ;;
type change = { coord : coord; destiny : destiny };;

let make_coord a b =
  { x = a; y = b };;

let enlarge box coord =
  let (minx, miny, maxx, maxy) = box in
  (min minx coord.x, min miny coord.y, max maxx coord.x, max maxy coord.y)
;;

let bbox lst =
  let x = Int32.MaxValue in
  let n = Int32.MinValue in
  Set.fold enlarge (x, x, n, n) lst
;;

let esc =
    Convert.ToChar 27;;

let printBoard s =
  printf "%c[2J" esc;
  printf "%c[;H" esc;
  let (minx, miny, maxx, maxy) = bbox s in
  for y = maxy downto miny do
    for x = minx to maxx do
      printf "%c" (if Set.contains (make_coord x y) s then '@' else ' ');
    done;
    printf "\n";
  done;
  System.Threading.Thread.Sleep( 1000 / 30)
  ()
;;

let make_change c d =
  { coord = c; destiny = d };;

let live c =
  make_change c Live

let die c =
  make_change c Die

let is destiny change =
    (compare change.destiny destiny) = 0
;;

let toLiveSet changeSet =
  Set.ofSeq (Set.map (fun x -> x.coord) changeSet)
;;

let applyChanges liveSet changes =
  let toLive = toLiveSet (Set.filter (is Live) changes) in
  let toDie = toLiveSet (Set.filter (is Die) changes) in
  Set.union toLive (Set.difference liveSet toDie)
;;

let eight coord =
  List.map (fun (x, y) -> { x = coord.x + x; y = coord.y + y }) [
      (-1,-1); (-1,0); (-1,1);
      (0,-1); (0, 1);
      (1,-1); (1, 0); (1, 1)];;

let computeNeighbors changes =
  let possible =
    Set.map (fun change -> change.coord) changes in
  Set.ofList(List.concat(List.map eight (Set.toList possible)));;

let neighborCount liveSet coord =
  List.length (List.filter (fun c -> Set.contains c liveSet) (eight coord));;

let computeChange liveSet coord =
  match neighborCount liveSet coord with
  | 2 -> None
  | 3 -> if (Set.contains coord liveSet) then None else Some (live coord)
  | _ -> if (Set.contains coord liveSet) then Some (die coord) else None
;;

let computeChanges liveSet neighbors =
  Set.ofList
        (List.choose (computeChange liveSet) (Set.toList neighbors))
;;

let rec run count liveSet changes =
  match count with
  | 0 -> ()
  | _ ->
     let updated = applyChanges liveSet changes in
     if show_work then
       printBoard updated
     else
       ();
     let neighbors = computeNeighbors changes in
     let nextGen = computeChanges updated neighbors in
     run (count - 1) updated nextGen
;;

let toLive xy =
  let (x, y) = xy in
  live (make_coord x y)
;;

let run1 ignored =
  let r_pentomino = [(0, 0); (0, 1); (1, 1); (-1, 0); (0, -1)] in
  let startChanges = Set.ofList (List.map toLive r_pentomino) in
  run generations (Set.empty) startChanges;;

let time f =
  let start = System.DateTime.Now in
  let res = f () in
  let diff = System.DateTime.Now.Subtract start in
  (res, diff.TotalMilliseconds / 1000.0)
;;

let main =
  for i = 1 to (if show_work then 1 else 5) do
    let (res, diff) = time run1 in
    printf "%.4f generations per sec\n" ((float generations) / diff)
  done
;;
