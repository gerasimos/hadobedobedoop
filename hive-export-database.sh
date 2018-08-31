#!/bin/bash

# TODO: support partitions
# TODO: handle kerberos
# TODO: handle permissions

source common.sh

usage="$(basename "$0") [-h] [--database string] [--export-hdfs-path string]

where:
	-h, --help,	shows this help text
	--database string,	the name of the database
	--export-hdfs-path string,	the export HDFS directory path
"

while [ "$1" != "" ]; do
	case $1 in
		-h|--help) echo "$usage"; exit 1
			;;
		--database) shift
			DATABASE=$1
			;;
		--export-hdfs-path) shift
			EXPORT_HDFS_PATH=$1
			;;
	esac
	shift
done

check_arg "--export-hdfs-path" "$EXPORT_HDFS_PATH"
check_arg "--database" "$DATABASE"

#### Main ####

HiveTables=$(hive -e "use ${DATABASE};show tables;" 2>/dev/null | egrep -v "WARN|^$|^Logging|^OK|^Time\ taken")

hdfs dfs -mkdir -p ${EXPORT_HDFS_PATH} 2>/dev/null

for Table in $HiveTables; do
    hive -e "EXPORT TABLE ${DATABASE}.$Table TO '${EXPORT_HDFS_PATH}/${DATABASE}.$Table';"
done
