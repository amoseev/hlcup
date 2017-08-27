-- @link http://lua-visits.org/wiki/ObjectOrientationTutorial

function VisitController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
    }

    function self.get(visitId)
        if is_identity(visitId) then else ngx.exit(400) end

        local redis = self.getRedis()
        local visit = createVisitFromRedisId(visitId, redis)
        if visit then
            ngx.say(visit.toJson())
        else
            ngx.status = 404
            ngx.print("Not found!")
            return
        end
    end

    function self.update(visitId, jsonString)
        if (visitId ~= 'new') then
            if is_identity(visitId) then else ngx.exit(400)  end
        end
        local redis = self.getRedis()
        local cjson = require('cjson')
        local tableVisit = cjson.decode(jsonString)
        if tableVisit then
            if (visitId == 'new') then
                local entityExisted = createVisitFromRedisId(tableVisit["id"], redis)
                if (entityExisted) then
                    ngx.exit(400) -- уже существует visit с ид
                end
            else
                tableVisit["id"] = visitId
            end
            local visit = createVisitFromTableParsedJson(tableVisit)

            if visit then
                local user = createUserFromRedisId(visit.user(), redis) --валидные связи
                if user then else ngx.exit(400)  end
                local location = createLocationFromRedisId(visit.location(), redis) -- валидные связи
                if location then else ngx.exit(400)  end
                if is_identity(visit.mark()) then else ngx.exit(400)  end
                if (visit.mark() > 5 or visit.mark() < 0) then
                    ngx.exit(400)
                end
                if is_identity(visit.visited_at()) then else ngx.exit(400)  end

                saveVisitToRedis(visit, redis)
            else
                -- ngx.log(ngx.ERROR, "cant create visit from json string " .. jsonString)
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
