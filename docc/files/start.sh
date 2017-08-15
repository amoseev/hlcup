#!/bin/bash

service supervisord start
service redis-server start
service nginx start

lua /var/multrix/lua/init/init.lua