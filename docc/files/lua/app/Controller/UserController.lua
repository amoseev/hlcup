-- @link http://lua-users.org/wiki/ObjectOrientationTutorial


local function string(o)
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
            if type(k) ~= 'number' then k = string(k) end
            s = s .. indent2 .. '[' .. k .. '] = ' .. recurse(v, indent2)
            first = false
        end
        return s .. '\n' .. indent .. '}'
    else
        return string(o)
    end
end

local function var_dump(...)
    local args = {...}
    if #args > 1 then
        var_dump(args)
    else
        ngx.say(recurse(args[1]))
    end
end



function UserController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
        public_field = 0
    }

    function self.get(userId)
        local redis = require "nginx.redis"
        local red = redis:new()
        local ok, err = red:connect("0.0.0.0", 6379)
        local userRD, err = red:hgetall("users:" .. userId)

        if err == nil then
            require "app.Domain.Users.User"
            local user = User(userRD)
            if user.isEmpty() then
                ngx.status = 404
                ngx.print("Not found!")
                return
            else
                ngx.say(user.toJson())
            end
        else
            ngx.status = ngx.ERROR
            ngx.log(ngx.ERROR, err)
        end

    end

    -- return the instance
    return self
end
