--
-- Получение списка мест, которые посетил пользователь: /users/<id>/visits.
-- В теле ответа ожидается структура {"visits": [ ... ]}, отсортированная по возрастанию дат, или ошибка 404/400. Подробнее - в примере.
-- Возможные GET-параметры:
-- fromDate - посещения с visited_at > fromDate
-- toDate - посещения с visited_at < toDate
-- country - название страны, в которой находятся интересующие достопримечательности
-- toDistance - возвращать только те места, у которых расстояние от города меньше этого параметра
--
require "app.Domain.Users.User"
require "app.Domain.Locations.Location"
require "app.Domain.Visits.Visit"

local function isemptyString(s)
    return s == nil or s == ''
end

local function isEmptyArray(arr)
    return next(arr) == nil
end

local function getVisitIds(user, searchParams, redis)
    local fromDate, toDate, country, toDistance
    if (searchParams["fromDate"]) then
        fromDate = searchParams["fromDate"]
    else
        fromDate = "-inf"
    end

    if (searchParams["toDate"]) then
        toDate = searchParams["toDate"]
    else
        toDate = "+inf"
    end

    if (searchParams["country"]) then
        country = searchParams["country"]
    else
        country = false
    end

    if (searchParams["toDistance"]) then
        toDistance = searchParams["toDistance"]
    else
        toDistance = false
    end

    local visitIds
    -- если только диапазон - то просто упорядоченные визиты пользователя
    if (toDistance == false and country == false) then
       -- var_dump(searchParams)
        visitIds =  redis:zrangebyscore("user_visits:" .. user.id() ..":visited_at", fromDate , toDate)
    end
    -- если только диапазон - то просто упорядоченные визиты пользователя
    if (toDistance == false and country ~= false) then
        var_dump(2)
        local tmpkey = "tmpkey_" .. math.random(1000000000)
        local keycountry = "user_visits:" .. user.id() .. ":country:" .. country
        local keyDate =  "user_visits:" .. user.id() .. ":visited_at"

        local ok, err = redis:zinterstore(tmpkey, 2, keycountry, keyDate, "AGGREGATE", "MAX")
        visitIds =  redis:zrangebyscore(tmpkey, fromDate , toDate)
    end

    if (visitIds == nil) then
        visitIds = {}
    end

    return visitIds
end


function SearchUserVisitsController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
    }

    function self.search(userId)

        if is_identity(userId) then else ngx.exit(404) end
        local cjson = require('cjson')

        local searchParams = {}
        for k,v in pairs(ngx.req.get_uri_args()) do
            if (k == "fromDate") then
                if is_identity(v) then else ngx.exit(400) end
                searchParams["fromDate"] = tonumber(v)
            end
            if (k == "toDate") then
                if is_identity(v) then else ngx.exit(400) end
                searchParams["toDate"] = tonumber(v)
            end
            if (k == "country") then
                if isemptyString(v) then ngx.exit(400) end
                searchParams["country"] = (v)
            end
            if (k == "toDistance") then
                if is_identity(v) then else ngx.exit(400) end
                searchParams["toDistance"] = tonumber(v)
            end
        end

        local redisIns = require "nginx.redis"
        local redis = redisIns:new()
        local ok, err = redis:connect("0.0.0.0", 6379)
        local user = createUserFromRedisId(userId, redis)

        if user then
            local visitIds = getVisitIds(user, searchParams, redis)
            local visit_responses = cjson.decode('[]');
            local visit, location
            for k,visitId in pairs(visitIds) do
                visit = createVisitFromRedisId(visitId, redis)
                location = createLocationFromRedisId(visit.location(), redis)

                visit_responses[k] = {mark = visit.mark(), visited_at= visit.visited_at(),  place = location.place(), distance = location.distance(), country = location.country()}
            end

            if (isEmptyArray(visit_responses)) then
                -- просто баг cjson. не хочется тратить время
                ngx.say('{"visits": []}')
            else
                ngx.say(cjson.encode({visits = visit_responses}))
            end

        else
            ngx.status = 404
            ngx.print("Not found!")
        end

    end

    -- return the instance
    return self
end