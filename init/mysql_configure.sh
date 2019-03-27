######## 
        #if ENV variables are provided in container use it as is, if not left use defaults
        ZM_DB_HOST=${ZM_DB_HOST:-localhost} && \
	ZM_DB_PORT=${ZM_DB_PORT:-3306} && \
	MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-mysqlpsswd} && \
	
	mysql -uroot < /usr/share/zoneminder/db/zm_create.sql && \
	mysql -uroot -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';" && \
	mysqladmin -uroot reload && \
	mysql -sfu root < "mysql_secure_installation.sql" && \
	rm mysql_secure_installation.sql && \
	mysql -sfu root < "mysql_defaults.sql" && \
	rm mysql_defaults.sql && \
	
        sed  -i "s|ZM_DB_HOST=localhost|ZM_DB_HOST=$ZM_DB_HOST|" /etc/zm/zm.conf && \
        sed  -i "s|MYSQL_ROOT_PASSWORD=mysqlpsswd|MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD|" /etc/zm/zm.conf && \
	#########
	mysql -uroot < /usr/share/zoneminder/db/zm_create.sql && \
	mysql -uroot -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';" && \
	mysqladmin -uroot reload && \
	mysql -sfu root < "mysql_secure_installation.sql" && \
	rm mysql_secure_installation.sql && \
	mysql -sfu root < "mysql_defaults.sql" && \
	rm mysql_defaults.sql
