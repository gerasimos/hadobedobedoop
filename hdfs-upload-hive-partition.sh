#!/bin/bash
# Author: gerasimos
# https://github.com/gerasimos

source common.sh

usage="$(basename "$0") [-h] <OPTIONS>

where <OPTIONS>:
	$(color green)-h, --help$(color),	shows this help text
	$(color green)--local-dir string$(color),	the local directory to upload from
	$(color green)--database string$(color),	the Hive database
	$(color green)--table string$(color),	the Hive table
	$(color green)--partition-by string$(color),	the partition key
	$(color green)--partition-value string$(color),	the partition value
	$(color green)--hive-warehouse string$(color),	the HDFS Hive warehouse directory
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
		--hive-warehouse)
			shift
			HIVE_WARESHOUSE=$1
			if [ "${HIVE_WARESHOUSE: -1}" != "/" ]; then
				HIVE_WARESHOUSE="${HIVE_WARESHOUSE}/"
			fi
			;;
		--local-dir) 
			shift
			LOCAL_DIR=$1
			# Add / at the end of the path if not exists
			if [ "${LOCAL_DIR: -1}" != "/" ]; then
				LOCAL_DIR="${LOCAL_DIR}/"
			fi
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
check_argument "--hive-warehouse" "$HIVE_WARESHOUSE"
check_argument "--local-dir" "$LOCAL_DIR"

echo "$(color green)==>$(color) Upload ${LOCAL_DIR}${PARTITION_BY}=${PARTITION_VALUE} --> ${HIVE_WARESHOUSE}${DATABASE}.db/${TABLE}/..."

hdfs dfs -put ${LOCAL_DIR}${PARTITION_BY}=${PARTITION_VALUE} ${HIVE_WARESHOUSE}${DATABASE}.db/${TABLE}/ || killme "Failed to hdfs"

echo "Done!"
