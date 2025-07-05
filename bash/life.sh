#! /usr/bin/env bash

declare -A alive

neighbors() {
    local x=$1
    local y=$2
    for xx in -1 0 1; do
	for yy in -1 0 1; do
	    if (($xx || $yy)) ; then
		echo $(($x + $xx)),$(($y + $yy))
	    fi
	done
    done
}

tick() {
    # compute the next generation in array "alive"
    local -A counts next
    local -a xy
    local x y pair r count
    for pair in ${!alive[@]}; do
	readarray -d "," -t xy <<< "${pair}"
	x=${xy[0]}
	y=${xy[1]}
	for neighbor in $(neighbors $x $y); do
	    true $((counts[${neighbor}]++))
	done
    done
    for r in ${!counts[@]}; do
	count=${counts[$r]}
	if (( count == 3 )) then
	   next[$r]=1
	else
	    if (( count == 2 && alive[$r] )) ; then
		next[$r]=1
	    fi
	fi
    done
    # reset the alive array
    alive=()
    for key in ${!next[@]} ; do
	alive[$key]=1
    done
}    


display() {
    echo -n "[2J[;H"
    for y in {12..-12}; do
	for x in {-40..39}; do
	    if [ -n "${alive["${x},${y}"]}" ] ; then
	     	echo -n "@"
	    else
	     	echo -n " "
	    fi
	done
	echo
    done
}

life() {
    initial="$1"
    generations="$2"
    showWork="$3"
    readarray -d " " -t pairs <<< "${initial}"
    for pair in ${pairs[@]}; do
	alive[${pair}]="1"
    done
    for ((generation=0;$generation < $generations; generation++)); do
        if $showWork ; then
	    display
	fi
	tick
    done
}    

generations=1000
r_pentomino="0,0 0,1 1,1 -1,0 0,-1 "
start=$(date +%s)
life "${r_pentomino}" ${generations} false
end=$(date +%s)
echo $((generations / (end - start) )) generations per second
