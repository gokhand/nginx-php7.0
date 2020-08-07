FROM ubuntu:18.04

# Let the container know that there is no tty
ENV DEBIAN_FRONTEN noninteractive

ENV NGINX_VERSION 1.14.0-0ubuntu1.7

RUN apt-get update && \
	apt-get install -y software-properties-common && \
	apt-get update

RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

RUN	dpkg-divert --local --rename --add /sbin/initctl && \
	ln -sf /bin/true /sbin/initctl && \
	mkdir /var/run/sshd && \
	mkdir /run/php && \
	add-apt-repository ppa:ondrej/php && \
	apt-get update && \
	apt-get install -y --no-install-recommends apt-utils \ 
		software-properties-common \
		language-pack-en-base && \
	LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php && \
	apt-get update && apt-get upgrade -y && \
	apt-get install -y python-setuptools \ 
		curl \
		git \
		nano \
		sudo \
		unzip \
		openssh-server \
		openssl \
		supervisor \
		memcached \
		ssmtp \
		cron && \
	apt-get update && apt-get -y install nginx=$NGINX_VERSION && \
	# Install PHP
	apt-get install -y php7.0-fpm \
		php7.0-mysql \
	    php7.0-curl \
	    php7.0-gd \
	    php7.0-intl \
		php7.0-redis \
	    php7.0-mcrypt \
	    php-memcache \
	    php7.0-sqlite \
	    php7.0-tidy \
	    php7.0-xmlrpc \
	    php7.0-pgsql \
	    php7.0-ldap \
	    freetds-common \
	    php7.0-pgsql \
	    php7.0-sqlite3 \
	    php7.0-json \
	    php7.0-xml \
	    php7.0-mbstring \
	    php7.0-soap \
	    php7.0-zip \
	    php7.0-cli \
	    php7.0-sybase \
	    php7.0-odbc

# Cleanup
RUN apt-get remove --purge -y software-properties-common \
	python-software-properties && \
	apt-get autoremove -y && \
	apt-get clean && \
	apt-get autoclean && \
	# install composer
	curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Nginx configuration
RUN sed -i -e"s/worker_processes  1/worker_processes 5/" /etc/nginx/nginx.conf && \
	sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
	sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 128m;\n\tproxy_buffer_size 256k;\n\tproxy_buffers 4 512k;\n\tproxy_busy_buffers_size 512k/" /etc/nginx/nginx.conf && \
	echo "daemon off;" >> /etc/nginx/nginx.conf && \
	# PHP-FPM configuration
	sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.0/cli/php.ini && \
	sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/cli/php.ini && \
	sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/cli/php.ini && \
	#sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/php-fpm.conf && \
	sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.0/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.0/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.0/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.0/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.0/fpm/pool.d/www.conf && \
	sed -i -e "/pid\s*=\s*\/run/c\pid = /run/php7.0-fpm.pid" /etc/php/7.0/fpm/php-fpm.conf && \
	sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.0/fpm/pool.d/www.conf && \
	# mcrypt configuration
	phpenmod mcrypt && \
	# remove default nginx configurations
	rm -Rf /etc/nginx/conf.d/* && \
	rm -Rf /etc/nginx/sites-available/default && \
	mkdir -p /etc/nginx/ssl/ && \
	# create workdir directory
	mkdir -p /var/www

RUN mkdir -p /var/run/php && \
	service php7.0-fpm start

COPY ./config/nginx/nginx.conf /etc/nginx/sites-available/default.conf
# Supervisor Config
COPY ./config/supervisor/supervisord.conf /etc/supervisord.conf
# Start Supervisord
COPY ./config/cmd.sh /
# mount www directory as a workdir
COPY ./www/ /var/www

RUN rm -f /etc/nginx/sites-enabled/default && \
	ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default && \
	chmod 755 /cmd.sh && \
	chown -Rf www-data.www-data /var/www && \
	touch /var/log/cron.log && \
	touch /etc/cron.d/crontasks

# Expose Ports
EXPOSE 80

ENTRYPOINT ["/bin/bash", "/cmd.sh"]