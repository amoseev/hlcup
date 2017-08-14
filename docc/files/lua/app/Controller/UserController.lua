-- @link http://lua-users.org/wiki/ObjectOrientationTutorial


function vd_string(o)
    return '"' .. tostring(o) .. '"'
end

function vd_recurse(o, indent)
    if indent == nil then indent = '' end
    local indent2 = indent .. '  '
    if type(o) == 'table' then
        local s = indent .. '{' .. '\n'
        local first = true
        for k,v in pairs(o) do
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
    local args = {...}
    if #args > 1 then
        var_dump(args)
    else
        ngx.say(vd_recurse(args[1]))
    end
end



function UserController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
    }

    function self.get(userId)
        local redis = require "nginx.redis"
        local red = redis:new()
        local ok, err = red:connect("0.0.0.0", 6379)
        local userRD, err = red:hgetall("users:" .. userId)

        if err == nil then
            require "app.Domain.Users.User"
            if canCreateUserFromRedisData(userRD) then
                local user = createUserFromRedisData(userRD)
                ngx.say(user.toJson())
            else
                ngx.status = 404
                ngx.print("Not found!")
                return
            end
        else
            ngx.status = ngx.ERROR
            ngx.log(ngx.ERROR, err)
        end

    end

    -- return the instance
    return self
end
