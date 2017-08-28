-- @link http://lua-users.org/wiki/ObjectOrientationTutorial

function LocationController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
    }

    function self.get(locationId)
        if is_identity(locationId) then else ngx.exit(400) end

        local redis = self.getRedis()
        local location = createLocationFromRedisId(locationId, redis)

        if location then
            ngx.say(location.toJson())
        else
            ngx.status = 404
            ngx.print("Not found!")
        end

    end

    function self.update(locationId, jsonString)

        if (locationId ~= 'new') then
            if is_identity(locationId) then else ngx.exit(400)  end
        end
        local redis = self.getRedis()
        local cjson = require('cjson')
        local tableLocation = cjson.decode(jsonString)
        if tableLocation then
            local location
            if (locationId == 'new') then
                local enityiExisted = createLocationFromRedisId(tableLocation["id"], redis)
                if (enityiExisted) then
                    ngx.exit(400) -- уже существует user с ид tableUser["id"]
                end
                location = createLocationFromTableParsedJson(tableLocation)
            else
                location = createLocationFromRedisId(locationId, redis)
                location.setFromTable(tableLocation)
            end

            if location then
                if (location.distance() < 0) then
                    ngx.exit(400)
                end
                saveLocationToRedis(location, redis)
                ngx.say("{}")
            else
                -- ngx.log(ngx.ERROR, "cant create location from json string " .. jsonString)
                ngx.exit(400)
            end
        else
            -- ngx.log(ngx.ERROR, "json decode error")
            ngx.exit(400)
        end

    end


    function self.getRedis()
        local redisIns = require "nginx.redis"
        local redis = redisIns:new()
        local ok, err = redis:connect("0.0.0.0", 6379)

        if err == nil then
            return redis
        else
            ngx.say(err)
        end
    end

    -- return the instance
    return self
end
