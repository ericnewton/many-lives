open Printf;;
open Unix;;

let generations = 1000;;
let show_work = false;;

type coord = {x : int; y : int};;
type destiny = Live | Die ;;
module LiveSet = Set.Make( 
  struct
    let compare = Stdlib.compare
    type t = coord
  end );;
type change = { coord : coord; destiny : destiny };;
module ChangeSet = Set.Make( 
  struct
    let compare = Stdlib.compare
    type t = change
  end );;

let make_coord a b =
  { x = a; y = b };;

let enlarge box coord =
  let (minx, miny, maxx, maxy) = box in
  (min minx coord.x, min miny coord.y, max maxx coord.x, max maxy coord.y)
;;

let bbox lst =
  let x = Int.max_int in
  let n = Int.min_int in
  Seq.fold_left enlarge (x, x, n, n) lst
;;

let esc =
  Char.chr 27;;

let printBoard s =
  printf "%c[2J" esc;
  printf "%c[;H" esc;
  let (minx, miny, maxx, maxy) = bbox (LiveSet.to_seq s) in
  for y = maxy downto miny do
    for x = minx to maxx do
      printf "%c" (if LiveSet.mem (make_coord x y) s then '@' else ' ');
    done;
    printf "\n%!";
  done;
  Unix.sleepf (1.0 /. 30.);
  ()
;;

let make_change c d =
  { coord = c; destiny = d };;

let live c =
  make_change c Live

let die c =
  make_change c Die

let is destiny change =
  destiny == change.destiny
;;

let toLiveSet changeSet =
  LiveSet.of_seq (Seq.map (fun x -> x.coord) (ChangeSet.to_seq changeSet))
;;

let applyChanges liveSet changes =
  let toLive = toLiveSet (ChangeSet.filter (is Live) changes) in
  let toDie = toLiveSet (ChangeSet.filter (is Die) changes) in
  LiveSet.union toLive (LiveSet.diff liveSet toDie)
;;

let eight coord =
  List.map (fun (x, y) -> { x = coord.x + x; y = coord.y + y }) [
      (-1,-1); (-1,0); (-1,1);
      (0,-1); (0, 1);
      (1,-1); (1, 0); (1, 1)];;

let computeNeighbors changes =
  let possible =
    List.map (fun change -> change.coord) (ChangeSet.elements changes) in
  LiveSet.of_list(List.flatten(List.map eight possible));;

let neighborCount liveSet coord =
  List.length (List.filter (fun c -> LiveSet.mem c liveSet) (eight coord));;

let computeChange liveSet coord =
  match neighborCount liveSet coord with
  | 2 -> None
  | 3 -> if (LiveSet.mem coord liveSet) then None else Some (live coord)
  | _ -> if (LiveSet.mem coord liveSet) then Some (die coord) else None
;;

let computeChanges liveSet neighbors =
  ChangeSet.of_list
        (List.filter_map (computeChange liveSet) (LiveSet.elements neighbors))
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
  let startChanges = ChangeSet.of_list (List.map toLive r_pentomino) in
  run generations (LiveSet.empty) startChanges;;

let time f =
  let start = Unix.gettimeofday () in
  let res = f () in
  let diff = Unix.gettimeofday () -. start in
  (res, diff)
;;

let main =
  for i = 1 to (if show_work then 1 else 5) do
    let (res, diff) = time run1 in
    printf "%.4f generations per sec\n%!" ((float_of_int generations) /. diff)
  done
;;
