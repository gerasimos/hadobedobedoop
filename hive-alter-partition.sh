#!/bin/bash
# Author: gerasimos
# https://github.com/gerasimos

source common.sh

usage="$(basename "$0") [-h] <OPTIONS>

where <OPTIONS>:
	$(color green)-h, --help$(color),	shows this help text
	$(color green)--database string$(color),	the Hive database
	$(color green)--table string$(color),	the Hive table
	$(color green)--partition-by string$(color),	the partition key
	$(color green)--partition-value string$(color),	the partition value
	$(color green)--action add|drop$(color),	the action to perform on the partition
	$(color green)--hive_warehouse string$(color),	the HDFS Hive warehouse (required for action==add)
"

while [ "$1" != "" ]; do
	case $1 in
		-h|--help) 
			echo "usage: $usage"; exit 1
			;;
		--database) 
			shift
			DATABASE=$1
			;;
		--table) 
			shift
			TABLE=$1
			;;
		--partition-by)
			shift
			PARTITION_BY=$1
			;;
		--partition-value)
			shift
			PARTITION_VALUE=$1
			;;
		--action)
			shift
			ACTION=$1
			if [ "$ACTION" != "add" ] && [ "$ACTION" != "drop" ]; then
				killme "Wrong --action value $ACTION."
			fi
			;;
		--hive_warehouse)
			shift
			HIVE_WAREHOUSE=$1
			;;
		*) 
			echo "ERROR: Unknown option $*."
			echo "usage: $usage"; exit 1
	esac
	shift
done

check_argument "--database" "$DATABASE"
check_argument "--table" "$TABLE"
check_argument "--partition-by" "$PARTITION_BY"
check_argument "--partition-value" "$PARTITION_VALUE"
check_argument "--action" "$ACTION"
if [ "$ACTION" == "add" ]; then
	check_argument "--hive_warehouse" "$HIVE_WAREHOUSE"
	kommand="ALTER TABLE ${DATABASE}.${TABLE} ADD PARTITION (${PARTITION_BY}='${PARTITION_VALUE}') LOCATION '${HIVE_WAREHOUSE}/${DATABASE}.db/${TABLE}/${PARTITION_BY}=${PARTITION_VALUE}';"

else
	kommand="ALTER TABLE ${DATABASE}.${TABLE} DROP IF EXISTS PARTITION (${PARTITION_BY}='${PARTITION_VALUE}') PURGE;"
fi

echo "$(color pine)Hive command: $kommand"

eval hive -e \"$kommand\"




