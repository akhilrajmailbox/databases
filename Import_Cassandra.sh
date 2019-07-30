#!/bin/bash

CASS_SNAP_FILE=$1
EXTRACT_SNAP="Cassandra-Backup-$$"

if [ -z "${CASS_SNAP_FILE}" ]; then
    echo "Usage import.sh [path to tar file]"
    exit 1
fi


until [[ ! -z "$CASS_HOST" ]] ; do
    echo "Cassandra listen Address must match [ listen_address ] and [ broadcast_rpc_address ] of cassandra.yml file"
    echo ""
    read -p "Enter the Cassandra listen Address :: " CASS_HOST </dev/tty
done



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
        cat "${EXTRACT_SNAP}/SCHEMA/${mykeyspace}.cql" | cqlsh

        for data_dir in "${EXTRACT_SNAP}/${mykeyspace}/"*; do
            sstableloader -d ${CASS_HOST} "${data_dir}"
        done
    done
}

Detect_keyspace
