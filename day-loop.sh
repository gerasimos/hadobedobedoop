#!/bin/bash
# Author: gerasimos
# https://github.com/gerasimos

source common.sh

usage="$(basename "$0") [-h] <OPTIONS>

where <OPTIONS>:
	$(color green)-h, --help$(color),	shows this help text
	$(color green)--from YYYY-MM-DD$(color),	the starting date to process (including)
	$(color green)--to YYYY-MM-DD$(color),	the ending date to process (including)
	$(color green)--script string$(color),	the script to execute per day
	$(color green)--date-as string$(color),	the argument name for date to pass to scrip. Default is 'date'
	$(color green)--varXXX string$(color),	defines variable XXX to pass to script
"

ARRAYIDX=0 VARS_NAME=() VARS_VALUE=()
FLAGSIDX=0 FLAGS=()
DATE_AS="date"
while [ "$1" != "" ]; do
	case $1 in
		-h|--help)
			echo "usage: $usage"; exit 1
			;;
		--from)
			shift
			START_DATE=$1
			;;
		--to)
			shift
			END_DATE=$1
			;;
		--var*)
			var=$1
			len=${#var}
			v=$(echo $1 | tail -c `expr $len - 4`)
			VARS_NAME[ARRAYIDX]=$v
			shift
			VARS_VALUE[ARRAYIDX]=$1
			((++ARRAYIDX))
			;;
		--flag*)
			flag=$1
			len=${#flag}
			f=$(echo $1 | tail -c `expr $len - 5`)
			FLAGS[FLAGSIDX]=$f
			((++FLAGSIDX))
			;;
		--script)
			shift
			SCRIPT=$1
			;;
		--date-as)
			shift
			DATE_AS=$1
			;;
		*)
			echo "ERROR: Unknown option $*."
			echo "usage: $usage"; exit 1
	esac
	shift
done

check_argument "--from" "$START_DATE"
check_argument "--to" "$END_DATE"
check_argument "--script" "$SCRIPT"

# Check if END_DATE is after START_DATE
if [[ "$START_DATE" > "$END_DATE" ]]; then
	echo "$(color red)ERROR: --from $START_DATE is after --to $END_DATE.$(color)"
	exit 1
fi

# Loop days
loopDate=$START_DATE
while [[ "$loopDate" < "$END_DATE" || "$loopDate" == "$END_DATE" ]]; do
	echo "$(color green)==>$(color) Processing $loopDate..."

	i=0 args=()
	for nn in ${VARS_NAME[*]}; do
		args[$i]="--$nn ${VARS_VALUE[$i]}"
		((++i))
	done

	for ff in ${FLAGS[*]}; do
		args[$i]="--$ff"
		((++i))
	done

	args[$i]="--$DATE_AS $loopDate"

	echo "arguments to call ./$SCRIPT: ${args[@]}"

	# run child script
	./$SCRIPT ${args[@]} || killme "$(basename "$0"): ERROR calling $SCRIPT"

	echo "$(color green)==>$(color) $loopDate OK"

	# Go to next date
	loopDate=$(date -d "$loopDate +1 day" +"%Y-%m-%d")
done
