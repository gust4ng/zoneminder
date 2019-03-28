#!/bin/bash
#
# mysql_configure.sh
#

ZM_DB_HOST=${ZM_DB_HOST:-localhost}
ZM_DB_PORT=${ZM_DB_PORT:-3306}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-mysqlpsswd}
ZM_DB_USER=${ZM_DB_USERNAME:-zmuser}
ZM_DB_PASS=${ZM_DB_PASSWORD:-zmpass}
	
if [[ $ZM_DB_HOST == "localhost" ]]; then
	mysql -uroot < /usr/share/zoneminder/db/zm_create.sql
	mysql -uroot -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';"
	mysqladmin -uroot reload
	mysql -sfu root < "mysql_secure_installation.sql"
	rm mysql_secure_installation.sql
	mysql -sfu root < "mysql_defaults.sql"
	rm mysql_defaults.sql
else
        sed  -i "s|ZM_DB_HOST=localhost|ZM_DB_HOST=$ZM_DB_HOST:$ZM_DB_PORT|" /etc/zm/zm.conf
	sed  -i "s|ZM_DB_USER=zmuser|ZM_DB_USER=$ZM_DB_USER|" /etc/zm/zm.conf
	sed  -i "s|ZM_DB_USER=zmpass|ZM_DB_USER=$ZM_DB_PASS|" /etc/zm/zm.conf
	mysql --host=$ZM_DB_HOST --port=$ZM_DB_PORT --user="root" --password="$MYSQL_ROOT_PASSWORD" < /usr/share/zoneminder/db/zm_create.sql
	mysql --host=$ZM_DB_HOST --port=$ZM_DB_PORT --user="root" --password="$MYSQL_ROOT_PASSWORD" -e "grant all on zm.* to '$ZM_DB_USER'@'%' identified by 'ZM_DB_PASS';"
	mysqladmin --host=$ZM_DB_HOST --port=$ZM_DB_PORT --user="root" --password="$MYSQL_ROOT_PASSWORD" reload
	mysql -sf --host=$ZM_DB_HOST --port=$ZM_DB_PORT --user="root" --password="$MYSQL_ROOT_PASSWORD" < "mysql_defaults.sql"
	rm mysql_defaults.sql
	rm mysql_secure_installation.sql
fi
