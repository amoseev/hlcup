package.path = "/var/multrix/lua/?.lua;;" .. package.path
-----------------
require "vendor.functions"
require "app.Domain.Users.User"
require "app.Domain.Locations.Location"
require "app.Domain.Visits.Visit"


local dirname = '/var/multrix/data'

local content
local cjson = require('cjson')
local redisClass = require "redis"
local redis = redisClass.connect("0.0.0.0", 6379)


local function readAll(path)
    local file = io.open(dirname .. '/' .. path, "rb") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

-----------------



-- users
local files = io.popen('/bin/ls ' .. dirname)
for fileName in files:lines() do
    if (string.match(fileName, 'users' )) ~= nil then
        content = readAll(fileName)
        local dataUsers = cjson.decode(content);
        table.foreach(dataUsers["users"], function( key, userTable )
            local user = createUserFromTableParsedJson(userTable)
            if user ~= false then
                saveUserToRedis(user, redis)
            end

        end)
    end
end

--locations
local files = io.popen('/bin/ls ' .. dirname)
for fileName in files:lines() do
    if (string.match(fileName, 'locations' )) ~= nil then
        content = readAll(fileName)
        local dataLocations = cjson.decode(content);
        table.foreach(dataLocations["locations"], function( key, locationTable )
            local location = createLocationFromTableParsedJson(locationTable)
            if location ~= false then
                saveLocationToRedis(location, redis)
            end

        end)
    end
end


--visits
local files = io.popen('/bin/ls ' .. dirname)
for fileName in files:lines() do
    if (string.match(fileName, 'visits')) ~= nil then
        content = readAll(fileName)
        local dataVisits = cjson.decode(content);
        table.foreach(dataVisits["visits"], function( key, visitTable )
            local visit = createVisitFromTableParsedJson(visitTable)
            if visit ~= false then
                saveVisitToRedis(visit, redis)
            end
        end)
    end
end

