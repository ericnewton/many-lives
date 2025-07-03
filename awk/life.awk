#! /usr/bin/env gawk -l time -f

# uses the "time" extension available in gawk/mawk/nawk to slow down
# the display (for debugging and watching life), and gettimeofday()
# to print metrics

function neighbors(x, y, result)
{
    for (xx = -1; xx <= 1; xx++)
	for (yy = -1; yy <= 1; yy++) {
	    if (xx || yy) {
		result[(x+xx) "," (y+yy)] += 1
	    }
	}
}
function tick(alive, result) {
    delete counts
    for (key in alive) {
	split(key, xy, ",");
        x = xy[1]
        y = xy[2]
	neighbors(x, y, counts)
    }
    delete result
    for (key in counts) {
	count = counts[key]
	if (count == 3 || (count == 2 && (key in alive))) {
	    result[key] = ""
	}
    }
}
function display(alive) {
    printf("%c[2J%c[;H", 27, 27)
    for (y = 10; y > -10; y--) {
	for (x = -40; x < 40; x++) {
	    if ((x "," y) in alive) {
		printf("@")
	    } else {
		printf(" ")
	    }
	}
	printf("\n")
    }
    sleep(1./30)		# extension
}
function copy(src, dest) {
    delete dest
    for (k in src)
	dest[k] = src[k]
}
function life(initial, generations, showWork) {
    split(initial, pairs, " ")
    for (k in pairs) {
	alive[pairs[k]] = ""
    }
    for (generation = 0; generation < generations; generation++) {
	if (showWork) {
	    display(alive)
	}
	tick(alive, result)
	copy(result, alive)
    }
}    

BEGIN {
    generations = 1000
    r_pentomino = "0,0 0,1 1,1 -1,0 0,-1"
    for (i = 0; i < 5; i++) {
	start = gettimeofday()	# gettimeofday is an extension
	life(r_pentomino, generations, 0)
	diff = gettimeofday() - start
	print generations/diff, "generations per second"
    }
}
