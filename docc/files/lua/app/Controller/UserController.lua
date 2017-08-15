-- @link http://lua-users.org/wiki/ObjectOrientationTutorial

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
