#!/bin/bash

CASS_DATA_DIR=/var/lib/cassandra/data
CASS_BACKUP_LOC=/opt/SaaS_Backup/Cass_Snapshots
CASS_BACKUP_COUNT=2
SNAP_DATE=`date +%F--%H-%M`
CASS_SNAP=Cassandra-Snapshot-${SNAP_DATE}


keyspace=(
	"test"
	"test1"
)

############################
function Pre_Check() {
    if ls ${CASS_BACKUP_LOC}/${CASS_SNAP}.tar.gz > /dev/null 2>&1; then
        echo "Backup Folder : ${CASS_SNAP}.tar.gz under ${CASS_BACKUP_LOC} already available.....!"
        echo "Either you are running this script too frequently (1 min minimum delay)...or something wrong in this... please contact DevOps team to solve this issue......!"
        exit 1
    else
        echo "${CASS_BACKUP_LOC}/${CASS_SNAP}.tar.gz will Create by nodetool snapshot.....!"
    fi
}


############################
function Cass_Clean() {
    Pre_Check
    while [[ $(ls ${CASS_BACKUP_LOC} | wc -l) -gt ${CASS_BACKUP_COUNT} ]] ; do
        rm -rf ${CASS_BACKUP_LOC}/$(ls ${CASS_BACKUP_LOC} | head -n 1)
        echo "${CASS_BACKUP_LOC}/$(ls ${CASS_BACKUP_LOC} | head -n 1) deleted.....!"
    done
}


############################
function Cass_Snap() {
    Cass_Clean
    for mykeyspace in ${keyspace[@]} ; do
        if cqlsh -e "use ${mykeyspace}" 2> /dev/null ; then
            echo "keyspace available....!"
            echo "Create snapshot having name: ${CASS_SNAP}"
            nodetool snapshot ${mykeyspace} -t ${CASS_SNAP}
        else
            echo "keyspace ${mykeyspace} not found.....!"
        fi
    done
}


############################
function Backup_Snap() {
    Cass_Snap
    for mykeyspace in ${keyspace[@]} ; do
        echo "Preparing cassandra backup file"
        if cqlsh -e "use ${mykeyspace}" 2> /dev/null ; then
            for name in $(find  "${CASS_DATA_DIR}/${mykeyspace}/"*"/snapshots/${CASS_SNAP}" -type f); do
                    new=$(echo "$name" | sed -e "s#${CASS_DATA_DIR}/##g" -e "s#\([^/]\+\)/\([^-]\+\).\+/snapshots/${CASS_SNAP}/\([^/]\+\)\$#\1/\2/\3#g")
                    mkdir -p "${CASS_BACKUP_LOC}/${CASS_SNAP}/$(dirname $new)"
                    cp "$name" "${CASS_BACKUP_LOC}/${CASS_SNAP}/$new"
            done
            echo "Dump schema for the keyspace ${mykeyspace}"
            mkdir -p "${CASS_BACKUP_LOC}/${CASS_SNAP}/SCHEMA"
            cqlsh -e "desc \"${mykeyspace}\";" > "${CASS_BACKUP_LOC}/${CASS_SNAP}/SCHEMA/${mykeyspace}.cql"
        else
            echo "keyspace ${mykeyspace} not found.....!"
        fi
    done
}


############################
function final_Snap() {
    Backup_Snap
    for mykeyspace in ${keyspace[@]} ; do
        if cqlsh -e "use ${mykeyspace}" 2> /dev/null ; then
            echo "Removing snapshot ${CASS_SNAP} for keyspace ${mykeyspace}....!"
            nodetool clearsnapshot ${mykeyspace} -t ${CASS_SNAP}
        else
            echo "keyspace ${mykeyspace} not found.....!"
        fi
    done

    echo "Create tar file: ${CASS_SNAP}.tar.gz"
    cd "${CASS_BACKUP_LOC}/${CASS_SNAP}"
    tar -czf "../${CASS_SNAP}.tar.gz" .
    cd -

    cd ${CASS_BACKUP_LOC}
    echo "Remove temp snap file"
    rm -rf "${CASS_SNAP}"
    cd -
}



final_Snap
