-- @link http://lua-users.org/wiki/ObjectOrientationTutorial

function UserController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
    }

    function self.get(userId)
        if is_identity(userId) then else ngx.exit(400) end

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

    function self.update(userId, jsonString)
        if is_identity(userId) then else ngx.exit(400)  end

        local redis = require "nginx.redis"
        local red = redis:new()
        local ok, err = red:connect("0.0.0.0", 6379)

        if err == nil then
            require "app.Domain.Users.User"

            local cjson = require('cjson')
            local tableUser = cjson.decode(jsonString)
            if tableUser then
                tableUser["id"] = userId
                local user = createUserFromTableParsedJson(tableUser)
                if user then
                    return red:hmset("users:" .. userId, user.getFields())
                else
                    -- ngx.log(ngx.ERROR, "cant create user from json string " .. jsonString)
                    ngx.exit(400)
                end
            else
                -- ngx.log(ngx.ERROR, "json decode error")
                ngx.exit(400)
            end
        else
            -- todo-deploy
            ngx.log(ngx.ERROR, err)
            ngx.exit(500)
        end
    end

    -- return the instance
    return self
end
