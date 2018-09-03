#!/bin/bash
# Author: gerasimos
# https://github.com/gerasimos

source common.sh

usage="$(basename "$0") [-h] <OPTIONS>

where <OPTIONS>:
	$(color blue)-h, --help$(color),	shows this help text
	$(color blue)--database string$(color),	the Hive database
	$(color blue)--table string$(color),	the Hive table
	$(color blue)--partition-by string$(color),	the partition key
	$(color blue)--partition-value string$(color),	the partition value
	$(color blue)--hive-warehouse string$(color),	the HDFS Hive warehouse directory
	$(color blue)--local-dir string$(color),	the local directory to download to
	$(color blue)--md5$(color),	if set, it compares the md5sum of each downloaded file with the HDFS one. $(color red)Can be very slow!$(color). If not set, only file size comparison if performed. 
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
			;;
		--md5)
			MD5_SUM=1
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

useMD5=""
if [ $MD5_SUM ]; then
	useMD5="--md5"
fi

eval ./hdfs-download-dir.sh --hdfs-dir ${HIVE_WARESHOUSE}${DATABASE}.db/${TABLE}/${PARTITION_BY}=${PARTITION_VALUE} --local-dir ${LOCAL_DIR} $useMD5 || killme "Failed executing hdfs-download-dir.sh"


