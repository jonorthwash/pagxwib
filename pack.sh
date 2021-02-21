#!/usr/bin/env bash

DIR=$1

ACTIVE_WINDOW=$(xdotool getactivewindow);
AW_GEOM=$(xdotool getwindowgeometry $ACTIVE_WINDOW);

#echo $AW_GEOM;

AW_DESKTOP=$(xdotool get_desktop_for_window $ACTIVE_WINDOW);
OTHER_WINDOWS=$(xdotool search --desktop $AW_DESKTOP --name '.*')

LEFTEDGE=$(xdotool getdisplaygeometry | cut -f1 -d' ')
BOTTOMEDGE=$(xdotool getdisplaygeometry | cut -f2 -d' ')

declare -A W_POSITIONS;

for otherwin in $OTHER_WINDOWS; do
	declare -A W_POSITIONS[$otherwin];
	dimensions=$(xdotool getwindowgeometry $otherwin);
	dim_POSN=$(echo $dimensions | sed -r 's/.*Position: ([0-9,]+) .*/\1/');
	dim_GEOM=$(echo $dimensions | sed -r 's/.*Geometry: ([0-9x]+).*/\1/');
	#echo $dimensions;
	#echo "---" $dim_POSN $dim_GEOM "---";
	TLx=$(echo $dim_POSN | cut -f1 -d,);
	TLy=$(echo $dim_POSN | cut -f2 -d,);
	dim_GEOM_W=$(echo $dim_GEOM | cut -f1 -dx);
	dim_GEOM_H=$(echo $dim_GEOM | cut -f2 -dx);
	BRx=$(echo "$TLx + $dim_GEOM_W" | bc);
	BRy=$(echo "$TLy + $dim_GEOM_H" | bc);

	#echo ${positions[TLx]} ${positions[TLy]} ${positions[BRx]} ${positions[BRy]};
	W_POSITIONS[$otherwin,TLx]=$TLx;
	W_POSITIONS[$otherwin,TLy]=$TLy;
	W_POSITIONS[$otherwin,BRx]=$BRx;
	W_POSITIONS[$otherwin,BRy]=$BRy;
	W_POSITIONS[$otherwin,H]=$dim_GEOM_H;
	W_POSITIONS[$otherwin,W]=$dim_GEOM_W;
	#declare -p W_POSITIONS
done;

POSSIBLE_PLACEMENTS=()
for otherwin in $OTHER_WINDOWS; do
	if [ $otherwin != $ACTIVE_WINDOW ]; then
		if [ $DIR == "R" ]; then
			# if window to the right
			if [ ${W_POSITIONS[$otherwin,TLx]} -gt ${W_POSITIONS[$ACTIVE_WINDOW,BRx]} ]; then
				# if it's between right edge of AW and edge of screen
				#echo "R of AW:" $otherwin ${W_POSITIONS[$otherwin,TLx]} ${W_POSITIONS[$ACTIVE_WINDOW,BRx]};
				#xdotool getwindowname $otherwin;
				if [[
					(
						(( ${W_POSITIONS[$otherwin,TLy]} -gt ${W_POSITIONS[$ACTIVE_WINDOW,TLy]} ))
						&&
						(( ${W_POSITIONS[$otherwin,TLy]} -lt ${W_POSITIONS[$ACTIVE_WINDOW,BRy]} ))
					) || (
						(( ${W_POSITIONS[$otherwin,BRy]} -lt ${W_POSITIONS[$ACTIVE_WINDOW,BRy]} ))
						&& 
						(( ${W_POSITIONS[$otherwin,BRy]} -gt ${W_POSITIONS[$ACTIVE_WINDOW,TLy]} ))
					) || (
						(( ${W_POSITIONS[$otherwin,BRy]} -gt ${W_POSITIONS[$ACTIVE_WINDOW,BRy]} ))
						&& 
						(( ${W_POSITIONS[$otherwin,TLy]} -lt ${W_POSITIONS[$ACTIVE_WINDOW,TLy]} ))
					)
					]]; then
					echo $otherwin;
					#echo ${W_POSITIONS[$otherwin,TLy]} "<" ${W_POSITIONS[$ACTIVE_WINDOW,TLy]} "&&" ${W_POSITIONS[$otherwin,BRy]} ">" ${W_POSITIONS[$ACTIVE_WINDOW,TLy]}
					#echo "||"
					#echo ${W_POSITIONS[$otherwin,BRy]} ">" ${W_POSITIONS[$ACTIVE_WINDOW,BRy]} "&&" ${W_POSITIONS[$otherwin,TLy]} "<" ${W_POSITIONS[$ACTIVE_WINDOW,BRy]}
					#xdotool getwindowname $otherwin;
					POSSIBLE_PLACEMENTS+=(${W_POSITIONS[$otherwin,TLx]})
				fi;
				#echo $otherwin;
				#xdotool getwindowgeometry $otherwin;
			fi;
			#xdotool windowmove I$ACTIVE_WINDOW x 0
			#xdotool getactivewindow windowmove 100 x	
			#echo "---"
		elif [ $DIR == "L" ]; then
			if [ ${W_POSITIONS[$otherwin,BRx]} -lt ${W_POSITIONS[$ACTIVE_WINDOW,TLx]} ]; then
				if [[
					(
						(( ${W_POSITIONS[$otherwin,TLy]} -gt ${W_POSITIONS[$ACTIVE_WINDOW,TLy]} ))
						&&
						(( ${W_POSITIONS[$otherwin,TLy]} -lt ${W_POSITIONS[$ACTIVE_WINDOW,BRy]} ))
					) || (
						(( ${W_POSITIONS[$otherwin,BRy]} -lt ${W_POSITIONS[$ACTIVE_WINDOW,BRy]} ))
						&& 
						(( ${W_POSITIONS[$otherwin,BRy]} -gt ${W_POSITIONS[$ACTIVE_WINDOW,TLy]} ))
					) || (
						(( ${W_POSITIONS[$otherwin,BRy]} -gt ${W_POSITIONS[$ACTIVE_WINDOW,BRy]} ))
						&& 
						(( ${W_POSITIONS[$otherwin,TLy]} -lt ${W_POSITIONS[$ACTIVE_WINDOW,TLy]} ))
					)
					]]; then		
					POSSIBLE_PLACEMENTS+=(${W_POSITIONS[$otherwin,BRx]})
				fi;
			fi;
		fi;
	fi;
done;

max=${POSSIBLE_PLACEMENTS[0]}
min=${POSSIBLE_PLACEMENTS[0]}

for placement in ${POSSIBLE_PLACEMENTS[@]}; do
	#echo $placement
	(( placement > max)) && max=$placement
	(( placement < min)) && min=$placement
done;

if [ ${#POSSIBLE_PLACEMENTS[@]} -gt 0 ]; then
	if [ $DIR == "R" ]; then
		#echo $min
		#xdotool getactivewindow windowmove $min x
		newX=$(echo $min - ${W_POSITIONS[$ACTIVE_WINDOW,W]} | bc);
		#echo $newX;
		xdotool getactivewindow windowmove $newX y
	elif [ $DIR == "L" ]; then
		newX=$max;
		xdotool getactivewindow windowmove $newX y
	fi;
else
	if [ $DIR == "R" ]; then
		newX=$(echo $LEFTEDGE - ${W_POSITIONS[$ACTIVE_WINDOW,W]} | bc);
		xdotool getactivewindow windowmove $newX y
	elif [ $DIR == "L" ]; then
		newX=0;
		xdotool getactivewindow windowmove $newX y
	fi;
fi;
