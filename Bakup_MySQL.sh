#!/bin/bash
## mysql_config_editor need to run for configuring encrypted MySQL Credentials in local file...
## mysql_config_editor set --login-path=Backup_Creds --host=localhost --user=wikima4 --password

MYSQL_CREDS=Backup_Creds
MYSQL_BACKUP_LOC=/opt/SaaS_Backup/MySQL_Backup
MYSQL_BACKUP_COUNT=5
BACKUP_DATE=`date +%F--%H-%M`
MYSQL_BACKUP=MySQL-Snapshot-${BACKUP_DATE}


Mysql_dbs=(
	"test"
	"test123"
)


############################
function Pre_Check() {
    if ls ${MYSQL_BACKUP_LOC}/${MYSQL_BACKUP} > /dev/null 2>&1; then
        echo "Backup Folder : ${MYSQL_BACKUP} under ${MYSQL_BACKUP_LOC} already available.....!"
        echo "Either you are running this script too frequently (1 min minimum delay)...or something wrong in this... please contact DevOps team to solve this issue......!"
        exit 1
    else
        mkdir ${MYSQL_BACKUP_LOC}/${MYSQL_BACKUP}
        echo "${MYSQL_BACKUP_LOC}/${MYSQL_BACKUP} Creating.....!"
    fi
}



############################
function MySQL_Clean() {
    Pre_Check
    while [[ $(ls ${MYSQL_BACKUP_LOC} | wc -l) -gt ${MYSQL_BACKUP_COUNT} ]] ; do
        rm -rf ${MYSQL_BACKUP_LOC}/$(ls ${MYSQL_BACKUP_LOC} | head -n 1)
        echo "${MYSQL_BACKUP_LOC}/$(ls ${MYSQL_BACKUP_LOC} | head -n 1) deleted.....!"
    done
}


############################
function MySQL_Backup() {
    MySQL_Clean
    for mydb in ${Mysql_dbs[@]} ; do
        if mysql --login-path=${MYSQL_CREDS} -e "use ${mydb}" 2> /dev/null ; then
            echo "Database available.....!"
            mysqldump --login-path=${MYSQL_CREDS} ${mydb} > ${MYSQL_BACKUP_LOC}/${MYSQL_BACKUP}/${mydb}.sql 2> /dev/null
        else
            echo "database ${mydb} not found.....!"
        fi
    done
}


############################
function final_Snap() {
    MySQL_Backup
    echo "Create tar file: ${MYSQL_BACKUP}.tar.gz"
    cd "${MYSQL_BACKUP_LOC}/${MYSQL_BACKUP}"
    tar -czf "../${MYSQL_BACKUP}.tar.gz" .
    cd -

    cd ${MYSQL_BACKUP_LOC}
    echo "Remove temp Backup file"
    rm -rf "${MYSQL_BACKUP}"
    cd -
}



final_Snap
