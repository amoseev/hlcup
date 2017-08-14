package.path = "/var/multrix/lua/?.lua;;" .. package.path

local dirname = '/var/multrix/data'

local content
local cjson = require('cjson')
local redisClass = require "redis"
local redis = redisClass.connect("0.0.0.0", 6379)


function readAll(path)
    local file = io.open(dirname .. '/' .. path, "rb") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

-----------------
local function string2(o)
    return '"' .. tostring(o) .. '"'
end

local function recurse(o, indent)
    if indent == nil then indent = '' end
    local indent2 = indent .. '  '
    if type(o) == 'table' then
        local s = indent .. '{' .. '\n'
        local first = true
        for k,v in pairs(o) do
            if first == false then s = s .. ', \n' end
            if type(k) ~= 'number' then k = string2(k) end
            s = s .. indent2 .. '[' .. k .. '] = ' .. recurse(v, indent2)
            first = false
        end
        return s .. '\n' .. indent .. '}'
    else
        return string2(o)
    end
end

local function var_dump(...)
    local args = {...}
    if #args > 1 then
        var_dump(args)
    else
        print(recurse(args[1]))
    end
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
local files = io.popen('/bin/ls ' .. dirname)
for fileName in files:lines() do
    if (string.match(fileName, 'locations' )) ~= nil then
        content = readAll(fileName)
        print(fileName)
    end
end
--visits
local files = io.popen('/bin/ls ' .. dirname)
for fileName in files:lines() do
    if (string.match(fileName, 'visits' )) ~= nil then
        content = readAll(fileName)
        print(fileName)
    end
end

