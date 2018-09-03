#!/bin/bash
# Author: gerasimos
# https://github.com/gerasimos

source common.sh

# $1=the file to keep
# $2=the final file path
# NOTE! $2 will be deleted if exists!
safe_replace_file() {
	mv ${2} ${2}.bak || killme "Could not move ${2} to ${2}.bak"
	mv ${1} ${2} || killme "Could not move ${1} to ${2}"
	rm ${2}.bak || killme "Could not delete ${2}.bak"
}

usage="$(basename "$0") [-h] [--hdfs-dir string] [--local-dir string] [--md5]

where:
	$(color green)-h, --help$(color),	shows this help text
	$(color green)--hdfs-dir string$(color),	the HDFS directory to download from
	$(color green)--local-dir string$(color),	the local directory to download to
	$(color green)--md5$(color),	if set, it compares the md5sum of each downloaded file with the HDFS one. $(color red)Can be very slow!$(color). If not set, only file size comparison if performed.
"

while [ "$1" != "" ]; do
	case $1 in
		-h|--help) 
			echo "usage: $usage"; exit 1
			;;
		--hdfs-dir) 
			shift
			HDFS_DIR=$1
			# Add / at the end of the path if not exists
			if [ "${HDFS_DIR: -1}" != "/" ]; then
				HDFS_DIR="${HDFS_DIR}/"
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
		--md5)
			MD5_SUM=1
			;;
		*) 
			echo "ERROR: Unknown option $*."
			echo "usage: $usage"; exit 1
	esac
	shift
done

check_argument "--hdfs-dir" "$HDFS_DIR"
check_argument "--local-dir" "$LOCAL_DIR"

# Main
hdfsDirListFile="~hdfs-dir-list.txt"
localValidationFile="~validation.txt"
statusFile="~status.txt"

echo "$(color pine)Will download ${HDFS_DIR} to ${LOCAL_DIR}"

mkdir -p ${LOCAL_DIR}
rm ${LOCAL_DIR}${hdfsDirListFile} 2>/dev/null
rm ${LOCAL_DIR}${localValidationFile} 2>/dev/null

echo "$(color green)Getting file listing of ${HDFS_DIR} in ${LOCAL_DIR}${hdfsDirListFile}...$(color)"
hdfs dfs -ls -R ${HDFS_DIR} > ${LOCAL_DIR}${hdfsDirListFile}.tmp
# This tail should be +0 in case of partitionied data or +2 in general case
# FIXME: Correct this tail
tail -n +0 ${LOCAL_DIR}${hdfsDirListFile}.tmp | sed -e 's/  */ /g' >> ${LOCAL_DIR}${hdfsDirListFile}
rm ${LOCAL_DIR}${hdfsDirListFile}.tmp

if [ ! -f "${LOCAL_DIR}${hdfsDirListFile}" ]; then
	killme "${LOCAL_DIR}${hdfsDirListFile} does not exist!"
fi

echo "$(color green)Processing ${LOCAL_DIR}${hdfsDirListFile}..."
while read permissions level user group size datee timee path; do
	pathDir=$(echo $path | sed -r -e "s;(.*)/(.*);\1;")
	pathFile=$(echo $path | sed -r -e "s;(.*)/(.*);\2;")
	relativePath=$(echo $path | sed -r -e "s;.*/(.*)/${pathFile};\1;")
	fileType=${permissions:0:1}
	echo "$fileType $pathDir $relativePath $pathFile $size" >> ${LOCAL_DIR}${hdfsDirListFile}.tmp
done < ${LOCAL_DIR}${hdfsDirListFile}

safe_replace_file ${LOCAL_DIR}${hdfsDirListFile}.tmp ${LOCAL_DIR}${hdfsDirListFile}

if [ $MD5_SUM ]; then
	echo "$(color green)MD5 calculation on HDFS files..."
	while read fileType hdfsDir relativePath filename size; do
		md5=0
		if [ "$fileType" == "-" ]; then
			# printf "MD5(${hdfsDir}/${filename})..."
			md5=$(hdfs dfs -cat "${hdfsDir}/${filename}" | md5sum | cut -d' ' -f1)
			# printf "${md5}\n"
		fi
		echo "$fileType $hdfsDir $relativePath $filename $size $md5" >> ${LOCAL_DIR}${hdfsDirListFile}.tmp
	done < ${LOCAL_DIR}${hdfsDirListFile}

	if [ ! -f "${LOCAL_DIR}${hdfsDirListFile}.tmp" ]; then
		killme "No ${LOCAL_DIR}${hdfsDirListFile}.tmp. Double check!"
	fi
	safe_replace_file ${LOCAL_DIR}${hdfsDirListFile}.tmp ${LOCAL_DIR}${hdfsDirListFile}
fi

echo "$(color green)Download directory ${HDFS_DIR} in ${LOCAL_DIR}...$(color)"
hdfs dfs -get ${HDFS_DIR} ${LOCAL_DIR}

echo "$(color green)Validate ${LOCAL_DIR}...$(color)"
while read fileType hdfsDir relativePath filename size md5; do
	if [ "$fileType" == "-" ]; then
		local_size=$(du -b "${LOCAL_DIR}${relativePath}/${filename}" | cut -f1)
		if [ "$size" -ne "$local_size" ]; then
			killme "Failed to validate size on $hdfsDir/$filename: $size != $local_size"
		fi

		if [ $MD5_SUM ]; then
			local_md5=$(md5sum "${LOCAL_DIR}${relativePath}/${filename}" | cut -d' ' -f1)
			if [ "$md5" != "$local_md5" ]; then
				killme "Failed to validate MD5 on $hdfsDir/$filename"
			fi
		fi
		echo "$hdfsDir/$filename $size $local_size $md5 $local_md5" >> ${LOCAL_DIR}${localValidationFile}
		
	elif [ ! -d "${LOCAL_DIR}${relativePath}/${filename}" ]; then
		killme "Failed to validate directory $hdfsDir/$filename"
	elif [ -d "${LOCAL_DIR}${relativePath}/${filename}" ]; then
		echo "$hdfsDir/$filename $size - $md5 -" >> ${LOCAL_DIR}${localValidationFile}
	fi
done < ${LOCAL_DIR}${hdfsDirListFile}

echo "Done!"

