SERVER=192.168.1.254
SERVERL=192.168.1.253
PORT=5432
USER=rep
PASSWORD=password

l_TELNET=`echo "quit" | telnet $SERVER $PORT | grep "Escape character is"`

if [ "$?" -ne 0 ]; then
touch /var/lib/postgresql/n1 || exit 0
fi

if [ -f "/var/lib/postgresql/9.5/main/recovery.done" ];then
if [ "`ping -c 1 $SERVER`" ]; then
ssh $SERVER "service postgresql stop" || ls
ssh $SERVER "echo '*:*:*:$USER:$PASSWORD' >> /var/lib/postgresql/.pgpass"
ssh $SERVER "chmod 0600 /var/lib/postgresql/.pgpass"
ssh $SERVER "rm -rf /var/lib/postgresql/9.5/main"
ssh $SERVER "pg_basebackup -v -D /var/lib/postgresql/9.5/main -R -P -h $SERVERL -p $PORT -U $USER"

#psql -c "select pg_start_backup('initial_backup');"
#rsync -cva --inplace --exclude=*pg_xlog* /var/lib/postgresql/9.5/main/ $SERVER:/var/lib/postgresql/9.5/main/
#psql -c "select pg_stop_backup();"

ssh $SERVER 'rm -rf "/var/lib/postgresql/9.5/main/recovery.done"'
ssh $SERVER 'cp "/var/lib/postgresql/recovery" "/var/lib/postgresql/9.5/main/recovery.conf"'
ssh $SERVER 'rm -rf "/var/lib/postgresql/n1"' || ls
ssh $SERVER "service postgresql start" || ls
rm -rf "/var/lib/postgresql/9.5/main/recovery.done"
fi
fi

