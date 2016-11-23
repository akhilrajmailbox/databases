SERVER=192.168.1.254
SERVERL=192.168.1.253
PORT=5432
USER=rep
PASSWORD=password
TRIGGER=/var/lib/postgresql/n1
VIRTUAL=192.168.1.150
NETMASK=255.255.255.0

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

l_TELNET=`echo "quit" | telnet $SERVER $PORT | grep "Escape character is"`
if [ "$?" -ne 0 ]; then
touch $TRIGGER || ls
ssh $SERVER "sudo ifconfig eth0:1 down" || ls
sudo ifconfig eth0:1 $VIRTUAL netmask $NETMASK
fi

if [ -f "/var/lib/postgresql/9.5/main/recovery.done" ]; then
if [ "`ping -c 3 $SERVER`" ]; then

ssh $SERVER "cat > /var/lib/postgresql/recovery << EOT
standby_mode = 'on'
primary_conninfo = 'host=$SERVERL port=$PORT user=$USER password=$PASSWORD'
trigger_file = '$TRIGGER'
EOT
"

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
#ssh $SERVER "service postgresql start" || ls
ssh $SERVER "/etc/init.d/postgresql start" || ls
rm -rf "/var/lib/postgresql/9.5/main/recovery.done"
fi
fi
