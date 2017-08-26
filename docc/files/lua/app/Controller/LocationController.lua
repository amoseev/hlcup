-- @link http://lua-users.org/wiki/ObjectOrientationTutorial

function LocationController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
    }

    function self.get(locationId)
        if is_identity(locationId) then else ngx.exit(400) end

        local redis = require "nginx.redis"
        local red = redis:new()
        local ok, err = red:connect("0.0.0.0", 6379)
        local locationRD, err = red:hgetall("locations:" .. locationId)

        if err == nil then
            require "app.Domain.Locations.Location"

            if canCreateLocationFromRedisData(locationRD) then
                local location = createLocationFromRedisData(locationRD)
                ngx.say(location.toJson())
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

    function self.update(locationId, jsonString)
        -- todo обработать изменение страны
        if is_identity(locationId) then else ngx.exit(400)  end

        local redisIns = require "nginx.redis"
        local redis = redisIns:new()
        local ok, err = redis:connect("0.0.0.0", 6379)

        if err == nil then
            require "app.Domain.Locations.Location"

            local cjson = require('cjson')
            local tableLocation = cjson.decode(jsonString)
            if tableLocation then
                tableLocation["id"] = locationId
                local location = createLocationFromTableParsedJson(tableLocation)
                if location then
                    saveLocationToRedis(location, redis)
                else
                    -- ngx.log(ngx.ERROR, "cant create location from json string " .. jsonString)
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
