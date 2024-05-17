create table offsets (
       x integer not null,
       y integer not null
       );

insert into offsets (x, y) values
 (-1, 1),
 (-1, 0),
 (-1, -1),
 (0, 1),
 (0, -1),
 (1, 1),
 (1, 0),
 (1, -1)
;

create table alive (
       generation integer not null,
       x integer not null,
       y integer not null,
       constraint pk_cell PRIMARY KEY (generation, x, y)
       );

insert into alive (generation, x, y)
 select 0, x, y from (
  values (0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)
 ) as r_pentomino (x, y)
 ;

create view neighbors as
    select generation, a.x + o.x as x, a.y + o.y as y
      from alive as a, offsets as o
;

create view counts as
    select generation, x, y, count(1) as n
      from neighbors
     group by generation, x, y
;

create view next_generation
as select c.generation as generation, c.x as x, c.y as y
     from counts c
     left
     join alive a
       on c.generation = a.generation
      and c.x = a.x
      and c.y = a.y
    where c.n = 2 and a.x is not null
       or c.n = 3
;


create procedure next(g integer)
language sql
as $$
    insert into alive (generation, x, y)
    select generation + 1, x, y
      from next_generation
     where generation = g;
$$;

-- I'm not smart enough to figure out how to do a recursive call for this
do $run_life$
begin
   for i in 0..1000 loop
      call next(i);
    end loop;
end
$run_life$;

-- view a 10x10 square of generation 100
-- create table board_coords (
--        x integer not null,
--        y integer not null,
--        constraint pk_mini_boeard primary key (x, y)
-- );
-- do $mini_board$
-- begin
--   for xx in -10..10 loop
--       for yy in -10..10 loop
--          insert into board_coords (x, y) values (xx, yy);
--       end loop;
--    end loop;
-- end
-- $mini_board$;

-- select gen as generation, y, board from (
-- select max(generation) gen, c.y, array_to_string(array_agg(
--               case when a.x is not null then 'x' else ' ' end order by c.x
--        	      ),
--        '') as board 
-- from board_coords c left join (
--   select generation, x, y from alive
--   group by generation, x, y
--   ) a on (c.y = a.y and c.x = a.x and generation = 100)
--   group by c.y
-- ) as out
-- order by y desc
-- ;
