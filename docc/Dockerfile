FROM ubuntu:14.04
MAINTAINER Emerson Estrella <emerson.estrella@gmail.com>

RUN DEBIAN_FRONTEND=noninteractive

# Update apt-get local index
RUN apt-get -qq update

# Install
RUN apt-get -y --force-yes install wget curl git unzip supervisor g++ make nginx mysql-server mysql-client redis-server php5-cli php5-fpm php5-dev php5-mysql php5-curl php5-intl php5-mcrypt php5-memcache php5-imap php5-sqlite
RUN apt-get -y --force-yes install nginx-extras lua-nginx-redis lua-cjson nano

RUN bash -c "wget http://getcomposer.org/composer.phar && mv composer.phar /usr/local/bin/composer && chmod +x /usr/local/bin/composer"

# PHP Redis
RUN mkdir -p /tmp/php-redis
WORKDIR /tmp/php-redis
RUN wget https://github.com/phpredis/phpredis/archive/2.2.5.zip; unzip 2.2.5.zip
WORKDIR /tmp/php-redis/phpredis-2.2.5
RUN /usr/bin/phpize; ./configure; make; make install
RUN echo "extension=redis.so" > /etc/php5/mods-available/redis.ini
RUN php5enmod redis


# PHP conf
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/cli/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
RUN sed -i "s/;daemonize = yes/daemonize = no/" /etc/php5/fpm/php-fpm.conf

# nginx conf
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf

ADD files/conf/site.conf /etc/nginx/sites-available/default
ADD files/conf/supervisord.conf /etc/supervisor/supervisord.conf
ADD files/conf/php-fpm.conf /etc/php5/fpm/php-fpm.conf
ADD files/start.sh /usr/local/bin/start.sh

COPY files/conf/redis.conf /etc/redis/redis.conf
COPY files/conf/nginx.conf /etc/nginx/nginx.conf

WORKDIR /var/multrix
RUN chown www-data:www-data /var/multrix
RUN service redis-server start

ADD phpapp/web/ /var/multrix/web/
ADD files/lua/ /var/multrix/lua/
RUN chown -R www-data:www-data /var/multrix
COPY data/data.zip /tmp/data/data.zip
RUN unzip -o /tmp/data/data.zip -d /var/multrix

# Expose ports
EXPOSE 80
EXPOSE 443
EXPOSE 6379


RUN chmod +x /usr/local/bin/start.sh
# Default command for container, start supervisor
CMD ["supervisord", "--nodaemon"]
CMD ["service", "redis-server", "start"]
CMD ["service", "php5-fpm", "start"]
CMD ["service", "nginx", "start"]
CMD ["/usr/local/bin/start.sh"]
