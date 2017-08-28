function Visit(id, user, location, visited_at, mark)
    -- the new instance
    local self = {
        fields = {
            id = tonumber(id),
            user = tonumber(user),
            location = tonumber(location),
            visited_at = tonumber(visited_at),
            mark = tonumber(mark)
        }
    }

    function self.toJson()
        -- todo кидать ошибку если пустой объект
        local cjson = require('cjson')
        return cjson.encode(self.fields)
    end

    function self.getFields()
        -- todo кидать ошибку если пустой объект
        return self.fields
    end

    function self.id()
        return self.fields["id"]
    end

    function self.user()
        return self.fields["user"]
    end

    function self.location()
        return self.fields["location"]
    end

    function self.visited_at()
        return self.fields["visited_at"]
    end

    function self.mark()
        return self.fields["mark"]
    end

    function self.set_user(user)
        if (is_identity(user) and user > 0) then
            self.fields["user"] = user
        else
            ngx.exit(400)
        end


    end

    function self.set_location(location)
        if (is_identity(location) and location > 0) then
            self.fields["location"] = location
        else
            ngx.exit(400)
        end


    end

    function self.set_visited_at(visited_at)
        if (is_identity(visited_at)) then
            self.fields["visited_at"] = visited_at
        else
            ngx.exit(400)
        end

    end

    function self.set_mark(mark)
        if (is_identity(mark) and mark >= 0 and mark <=5) then
            self.fields["mark"] = mark
        else
            ngx.exit(400)
        end

    end

    function self.setFromTable(tableLocation)
        if (tableLocation["user"]) then
            self.set_user(tableLocation["user"])
        end
        if (tableLocation["location"]) then
            self.set_location(tableLocation["location"])
        end
        if (tableLocation["visited_at"]) then
            self.set_visited_at(tableLocation["visited_at"])
        end
        if (tableLocation["mark"]) then
            self.set_mark(tableLocation["mark"])
        end
    end

    -- return the instance
    return self
end

function createVisitFromRedisId(visitId, redis)
    if (is_identity(visitId)) then else ngx.exit(400) end

    local visitRD, err = redis:hgetall("visits:" .. visitId)
    if err == nil then
        return createVisitFromRedisData(visitRD)
    else
        return false;
    end
end


function createVisitFromRedisData(redisData)
    if (canCreateVisitFromRedisData(redisData)) then
        local visitObjHashTable = {};
        if(redisData["id"]) then
            visitObjHashTable = redisData
        else
            local propertyTemp;
            local isPropertyTemp = true;
            for k,v in pairs(redisData) do
                if isPropertyTemp then
                    propertyTemp = v
                    isPropertyTemp = false
                else
                    visitObjHashTable[propertyTemp] = v
                    isPropertyTemp = true
                end
            end
        end
        return Visit(visitObjHashTable['id'], visitObjHashTable["user"], visitObjHashTable["location"], visitObjHashTable["visited_at"], visitObjHashTable["mark"], visitObjHashTable["email"])
    else
        return false;
    end
end

function createVisitFromTableParsedJson(tableVisit)
    if (canCreateVisitFromTableParsedJson(tableVisit)) then
        return Visit(tableVisit['id'], tableVisit["user"], tableVisit["location"], tableVisit["visited_at"], tableVisit["mark"])
    else
        return false;
    end
end


function canCreateVisitFromRedisData(redisData)
    return next(redisData) ~= nil
end

function canCreateVisitFromTableParsedJson(tableVisit)
    local required = {"id", "user", "location", "visited_at", "mark"}

    for key,field in pairs(required) do
        if (tableVisit[field] == nil or tableVisit[field] == "null" or isEmptyString(tableVisit[field])) then
            return false
        end
    end

    return true
end

function saveVisitToRedis(visit, redis)
    if visit == false then
        return
    end

    local key
    local visitOld = createVisitFromRedisId(visit.id(), redis)

    if (visitOld ~= false) then
        --список мест, которые посетил пользователь для конкретной локации
        key = "user_visits:" ..  visitOld.user().. ":location:" .. visitOld.location()
        redis:srem(key, visitOld.id())

        -- упорядоченный по дате список визитов пользователя
        key = "user_visits:" ..  visitOld.user().. ":visited_at" .. visitOld.visited_at()
        redis:zrem(key, visitOld.id())

        local location = createLocationFromRedisId(visitOld.location(), redis)
        --список мест, которые посетил пользователь для конкретной страны
        key = "user_visits:" ..  visitOld.user().. ":country:" .. location.country()
        redis:srem(key, visitOld.id())

        --упорядоченный по расстоянию список визитов пользователя
        key = "user_visits:" ..  visitOld.user().. ":distance"
        redis:zrem(key, visitOld.id())

        -- усписок визитов для локации всех пользователей
        key = "user_visits:location:" .. visit.location()
        redis:srem(key, visit.id())

    end

    key = "visits:" ..  visit.id()
    redis:hmset(key, visit.getFields())

    -- упорядоченный по дате список визитов пользователя
    key = "user_visits:" ..  visit.user().. ":visited_at"
    redis:zadd(key, visit.visited_at(), visit.id())

    local location = createLocationFromRedisId(visit.location(), redis)
    --список мест, которые посетил пользователь для конкретной страны
    key = "user_visits:" ..  visit.user().. ":country:" .. location.country()
    redis:sadd(key, visit.id())

    --упорядоченный по расстоянию список визитов пользователя
    key = "user_visits:" ..  visit.user().. ":distance"
    redis:zadd(key, location.distance(), visit.id())

    -- усписок визитов для локации всех пользователей
    key = "user_visits:location:" .. visit.location()
    redis:sadd(key, visit.id())
end

function updateVisitsLocationKeys(location, locationOld, redis)
    if (location.distance() ~= locationOld.distance() or location.country() ~= locationOld.country()) then
        local key
        key = "user_visits:location:" .. location.id()
        local visitIds = redis:smembers(key)
        local visit
        for k, visitId in pairs(visitIds) do
            visit = createVisitFromRedisId(visitId, redis)
            if (location.country() ~= locationOld.country()) then
                -- old remove
                key = "user_visits:" ..  visit.user().. ":country:" .. locationOld.country()
                redis:srem(key, visit.id())
                -- new add
                key = "user_visits:" ..  visit.user().. ":country:" .. location.country()
                redis:sadd(key, visit.id())
            end
            if (location.distance() ~= locationOld.distance()) then
                key = "user_visits:" ..  visit.user().. ":distance"
                redis:zrem(key, visit.id()) -- old remove
                redis:zadd(key, location.distance(), visit.id()) -- new add
            end
        end
    end
end