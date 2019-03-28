FROM dlandon/baseimage

LABEL maintainer="dlandon"

ENV	PHP_VERS="7.1"
ENV	ZM_VERS="1.32"
ENV	ZMEVENT_VERS="3.3"

ENV	SHMEM="50%" \
	PUID="99" \
	PGID="100"

COPY init/ /etc/my_init.d/
COPY defaults/ /root/
COPY zmeventnotification/zmeventnotification.pl /usr/bin/
COPY zmeventnotification/zmeventnotification.ini /root/

RUN add-apt-repository -y ppa:iconnor/zoneminder-$ZM_VERS && \
	add-apt-repository ppa:ondrej/php && \
	apt-get update && \
	apt-get -y upgrade -o Dpkg::Options::="--force-confold" && \
	apt-get -y dist-upgrade && \
	apt-get -y install apache2 mariadb-server && \
	apt-get -y install ssmtp mailutils net-tools libav-tools wget sudo make && \
	apt-get -y install php$PHP_VERS php$PHP_VERS-fpm libapache2-mod-php$PHP_VERS php$PHP_VERS-mysql php$PHP_VERS-gd && \
	apt-get -y install libcrypt-mysql-perl libyaml-perl libjson-perl && \
	apt-get -y install zoneminder

RUN	rm /etc/mysql/my.cnf && \
	cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/my.cnf && \
	adduser www-data video && \
	a2enmod php$PHP_VERS proxy_fcgi ssl rewrite expires headers && \
	a2enconf php$PHP_VERS-fpm zoneminder && \
	echo "extension=apcu.so" > /etc/php/$PHP_VERS/mods-available/apcu.ini && \
	echo "extension=mcrypt.so" > /etc/php/$PHP_VERS/mods-available/mcrypt.ini && \
	perl -MCPAN -e "force install Net::WebSocket::Server" && \
	perl -MCPAN -e "force install LWP::Protocol::https" && \
	perl -MCPAN -e "force install Config::IniFiles" && \
	perl -MCPAN -e "force install Net::MQTT::Simple"

RUN	cd /root && \
	wget www.andywilcock.com/code/cambozola/cambozola-latest.tar.gz && \
	tar xvf cambozola-latest.tar.gz && \
	cp cambozola*/dist/cambozola.jar /usr/share/zoneminder/www && \
	rm -rf cambozola*/ && \
	rm -rf cambozola-latest.tar.gz && \
	chmod 775 /usr/share/zoneminder/www/cambozola.jar && \
	chown -R www-data:www-data /usr/share/zoneminder/ && \
	echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
	sed -i "s|^;date.timezone =.*|date.timezone = ${TZ}|" /etc/php/$PHP_VERS/apache2/php.ini && \
	rm -f /etc/apache2/sites-enabled/000-default.conf && \
	rm -f /etc/apache2/sites-available/000-default.conf && \
	service mysql start

CMD	read -p "Press enter to configure MySQL..."
COPY	init/mysql_configure.sh /tmp/mysql_configure.sh
ENTRYPOINT	["/tmp/mysql_configure.sh"];
	
RUN	mv /root/zoneminder /etc/init.d/zoneminder && \
	chmod +x /etc/init.d/zoneminder && \
	service mysql restart && \
	sleep 5 && \
	service apache2 restart && \
	service zoneminder start

RUN	systemd-tmpfiles --create zoneminder.conf && \
	mv /root/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf && \
	mkdir /etc/apache2/ssl/ && \
	chmod a+x /usr/bin/zmeventnotification.pl && \
	mkdir -p /var/lib/zmeventnotification/images && \
	chown -R www-data:www-data /var/lib/zmeventnotification/ && \
	chmod -R +x /etc/my_init.d/ && \
	cp -p /etc/zm/zm.conf /root/zm.conf && \
	echo "#!/bin/sh\n\n/usr/bin/zmaudit.pl -f" >> /etc/cron.weekly/zmaudit && \
	chmod +x /etc/cron.weekly/zmaudit

RUN	apt-get -y remove wget make && \
	apt-get -y clean && \
	apt-get -y autoremove && \
	rm -rf /tmp/* /var/tmp/*

VOLUME \
	["/config"] \
	["/var/cache/zoneminder"]

EXPOSE 80 443 9000
