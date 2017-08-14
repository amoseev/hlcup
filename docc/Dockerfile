FROM ubuntu:14.04
MAINTAINER Artem Moseev<moseevartem@gmail.com>

RUN DEBIAN_FRONTEND=noninteractive

# Update apt-get local index
RUN apt-get -qq update

# Install
RUN apt-get -y --force-yes install wget curl git unzip supervisor g++ make nginx mysql-server mysql-client redis-server php5-cli php5-fpm php5-dev php5-mysql php5-curl php5-intl php5-mcrypt php5-memcache php5-imap php5-sqlite
RUN apt-get -y --force-yes install nginx-extras lua-nginx-redis lua-cjson nano "lua5.1"
RUN apt-get -y --force-yes install luajit luarocks
RUN apt-get -y --force-yes install libssl1.0.0 libssl-dev
RUN luarocks install inspect
RUN luarocks install luasec OPENSSL_LIBDIR=/usr/lib/x86_64-linux-gnu/
RUN   luarocks install luasocket && \
   luarocks install redis-lua

ADD files/conf/site.conf /etc/nginx/sites-available/default
ADD files/conf/supervisord.conf /etc/supervisor/supervisord.conf
ADD files/start.sh /usr/local/bin/start.sh

COPY files/conf/redis.conf /etc/redis/redis.conf
COPY files/conf/nginx.conf /etc/nginx/nginx.conf

WORKDIR /var/multrix
RUN chown www-data:www-data /var/multrix
RUN service redis-server start
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
CMD ["/usr/local/bin/start.sh"]
#CMD ["sh", "-c", "mkdir /var/multrix/lua2" ]
