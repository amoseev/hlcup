package.path = "/var/multrix/lua/?.lua;;" .. package.path

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
function vd_string(o)
    return '"' .. tostring(o) .. '"'
end


function vd_recurse(o, indent)
    if indent == nil then indent = '' end
    local indent2 = indent .. '  '
    if type(o) == 'table' then
        local s = indent .. '{' .. '\n'
        local first = true
        for k, v in pairs(o) do
            if first == false then s = s .. ', \n' end
            if type(k) ~= 'number' then k = vd_string(k) end
            s = s .. indent2 .. '[' .. k .. '] = ' .. vd_recurse(v, indent2)
            first = false
        end
        return s .. '\n' .. indent .. '}'
    else
        return vd_string(o)
    end
end

function var_dump(...)
    local args = { ... }
    if #args > 1 then
        var_dump(args)
    else
        ngx.say(vd_recurse(args[1]))
    end
end

function is_identity(n)
    -- todo 32 битное целое
    if tonumber(n) ~= nil then
        return true
    end;

    return false
end

-----------------
require "app.Domain.Users.User"
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
require "app.Domain.Locations.Location"
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
require "app.Domain.Visits.Visit"
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

