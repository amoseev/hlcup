-- @link http://lua-visits.org/wiki/ObjectOrientationTutorial

function VisitController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
    }

    function self.get(visitId)
        if is_identity(visitId) then else ngx.exit(400) end

        local redis = require "nginx.redis"
        local red = redis:new()
        local ok, err = red:connect("0.0.0.0", 6379)
        local visitRD, err = red:hgetall("visits:" .. visitId)

        if err == nil then
            if canCreateVisitFromRedisData(visitRD) then
                local visit = createVisitFromRedisData(visitRD)
                ngx.say(visit.toJson())
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

    function self.update(visitId, jsonString)
        if is_identity(visitId) then else ngx.exit(400)  end

        local redis = require "nginx.redis"
        local red = redis:new()
        local ok, err = red:connect("0.0.0.0", 6379)

        if err == nil then

            local cjson = require('cjson')
            local tableVisit = cjson.decode(jsonString)
            if tableVisit then
                tableVisit["id"] = visitId
                local visit = createVisitFromTableParsedJson(tableVisit)
                if visit then
                    saveVisitToRedis(visit, redis)
                else
                    -- ngx.log(ngx.ERROR, "cant create visit from json string " .. jsonString)
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
