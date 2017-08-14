#!/bin/bash

service redis-server start
service nginx start

lua /var/multrix/lua/init/init.lua