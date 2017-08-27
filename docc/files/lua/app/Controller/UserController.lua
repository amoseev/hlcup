-- @link http://lua-users.org/wiki/ObjectOrientationTutorial

function UserController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
    }

    function self.get(userId)
        if is_identity(userId) then else ngx.exit(400) end

        local redis = self.getRedis()
        local user = createUserFromRedisId(userId, redis)

        if user then
            ngx.say(user.toJson())
        else
            ngx.status = 404
            ngx.print("Not found!")
            return
        end
    end

    function self.update(userId, jsonString)
        if (userId ~= 'new') then
            if is_identity(userId) then else ngx.exit(400)  end
        end
        local redis = self.getRedis()
        local cjson = require('cjson')
        local tableUser = cjson.decode(jsonString)
        if tableUser then
            if (userId == 'new') then
                local userExisted = createUserFromRedisId(tableUser["id"], redis)
                if (userExisted) then
                    ngx.exit(400) -- уже существует user с ид tableUser["id"]
                end
            else
                tableUser["id"] = userId
            end
            local user = createUserFromTableParsedJson(tableUser)
            if user then
                saveUserToRedis(user, redis)
            else
                -- ngx.log(ngx.ERROR, "cant create user from json string " .. jsonString)
                ngx.exit(400)
            end
        else
            --ngx.log(ngx.ERROR, "json decode error")
            ngx.exit(400)
        end
    end


    function self.getRedis()
        local redisIns = require "nginx.redis"
        local redis = redisIns:new()
        local ok, err = redis:connect("0.0.0.0", 6379)

        if err == nil then
            return redis
        end
    end

    -- return the instance
    return self
end
