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
	$(color green)--hive-warehouse string$(color),	the HDFS Hive warehouse directory
	$(color green)--local-dir string$(color),	the local directory to download to
	$(color green)--md5$(color),	if set, it compares the md5sum of each downloaded file with the HDFS one. $(color red)Can be very slow!$(color). If not set, only file size comparison if performed.
	$(color green)--zip$(color),	if set, it compress the local-dir using tar.
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
		--zip)
			ZIPPER=1
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

rm -rf {LOCAL_DIR}/${PARTITION_BY}=${PARTITION_VALUE}

eval ./hdfs-download-dir.sh --hdfs-dir ${HIVE_WARESHOUSE}${DATABASE}.db/${TABLE}/${PARTITION_BY}=${PARTITION_VALUE} --local-dir ${LOCAL_DIR} $useMD5 || killme "Failed executing hdfs-download-dir.sh"

if [ $ZIPPER ]; then

	tar -zcvf ${LOCAL_DIR}/${PARTITION_BY}=${PARTITION_VALUE}.tar.gz ${LOCAL_DIR}/${PARTITION_BY}=${PARTITION_VALUE} || killme "Failed to tar ${LOCAL_DIR}/${PARTITION_BY}=${PARTITION_VALUE}"

	rm -rf ${LOCAL_DIR}/${PARTITION_BY}=${PARTITION_VALUE}
fi
