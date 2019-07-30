#!/bin/bash
MYSQL_HOST=localhost
MYSQL_BACKUP_FILE=$1
EXTRACT_BACKUP="MySQL-Backup-$$"
BACKUP_DATE=`date +%F--%H-%M`
MYSQL_BACKUP=DB_BaK-$BACKUP_DATE

if [[ -z "${MYSQL_BACKUP_FILE}" ]] ; then
    echo "Usage import.sh [path to tar file]"
    exit 1
fi


############################
function Extract_Backup() {
    mkdir -p "${EXTRACT_BACKUP}"
    tar -xvzf "${MYSQL_BACKUP_FILE}" -C "${EXTRACT_BACKUP}"
}


############################
function Detect_dbs() {
    Extract_Backup
    for mydbdump in ${EXTRACT_BACKUP}/*.sql ; do
        mydb=$(basename $mydbdump ".sql")
        echo "Working on Database : ${mydb}"

        mkdir ${MYSQL_BACKUP}
        echo "Take BackUp of Database ${mydb}.....Give me Permission to take dump of existing Database, delete and import...!!!!"

        until [[ ! -z "$MYSQL_USER" ]] ; do
            read -s -p "Enter MySQL user name :: " MYSQL_USER </dev/tty
        done

        until [[ ! -z "$MYSQL_PASS" ]] ; do
            read -s -p "Enter MySQL Password for user $MYSQL_USER :: " MYSQL_PASS </dev/tty
        done

        mysql -u ${MYSQL_USER} -p${MYSQL_PASS} -e "show databases;" > /dev/null
        if [[ $? -ne 0 ]] ; then
            echo "Task -- Mysql Conenction for localhost -- failed"
            exit 1
        fi

        DB_CHECK_RESULT=`mysqlshow -u ${MYSQL_USER} -p${MYSQL_PASS} ${mydb} | grep -v Wildcard | grep -o ${mydb}`
        if [ "$RESULT" == ${mydb} ]; then
            mysqldump -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASS} ${mydb} > ${MYSQL_BACKUP}/${mydbdump}
            if [[ $? -ne 0 ]] ; then
                echo "Task -- Take BackUp of Database ${mydb} -- failed"
                exit 1
            fi
        else
            echo "Database ${mydb} not available.....!"
        fi

        echo "Deleting Database ${mydb}"
        mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASS} -e "DROP DATABASE ${mydb} ; CREATE DATABASE ${mydb} ;"
        if [[ $? -ne 0 ]] ; then
            echo "Task -- Deleting Database ${mydb} -- failed"
            exit 1
        fi
        echo "Importing Database ${mydb}"
        mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASS} ${mydb} < ${mydbdump}
        if [[ $? -ne 0 ]] ; then
            echo "Task -- Importing Database ${mydb} -- failed"
            exit 1
        fi
    done
}

Detect_dbs
