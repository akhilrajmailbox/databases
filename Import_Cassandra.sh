#!/bin/bash

CASS_SNAP_FILE=$1
EXTRACT_SNAP="Snapshot-$$"

if [ -z "${CASS_SNAP_FILE}" ]; then
    echo "Usage import.sh [path to tar file]"
    exit 1
fi


############################
function Extract_Snap() {
    mkdir -p "${EXTRACT_SNAP}"
    tar -xvzf "${CASS_SNAP_FILE}" -C "${EXTRACT_SNAP}"
}


############################
function Detect_keyspace() {
    Extract_Snap
    Schema_List=$(ls ${EXTRACT_SNAP}/SCHEMA/*.cql)
    for mykeyspacelist in $Schema_List ; do
        mykeyspace=$(basename $mykeyspacelist ".cql")
        echo "Working on keyspace : ${mykeyspace}"

        echo "Drop keyspace ${mykeyspace}"
        cqlsh -e "drop keyspace \"${mykeyspace}\";"

        echo "Create empty keyspace: ${mykeyspace}"
        cat "${EXTRACT_SNAP}/SCHEMA/${mykeyspace}.sql" | cqlsh

        for data_dir in "${EXTRACT_SNAP}/${mykeyspace}/"*; do
            sstableloader -d localhost "${data_dir}"
        done
    done
}

Detect_keyspace