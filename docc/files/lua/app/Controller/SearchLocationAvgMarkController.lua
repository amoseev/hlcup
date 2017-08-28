--
-- Получение средней оценки достопримечательности: /locations/<id>/avg.
-- В ответе ожидается одно число, с точностью до 5 десятичных знаков (округляется по стандартным правилам округления), либо код 400/404. В случае, если не найдено ни одного подходящего посещения, то в ответе нужно вернуть avg=0.0.
-- Возможные GET-параметры:
-- fromDate - учитывать оценки только с visited_at > fromDate
-- toDate - учитывать оценки только с visited_at < toDate
-- fromAge - учитывать только путешественников, у которых возраст (считается от текущего timestamp) больше этого параметра
-- toAge - как предыдущее, но наоборот
-- gender - учитывать оценки только мужчин или женщин
-- В случае если места с переданным id нет - отдавать 404. Если по указанным параметрам не было посещений, то {"avg": 0}


local function getVisitIds(user, searchParams, redis)
    local fromDate, toDate, fromAge, toAge, gender
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

    if (searchParams["fromAge"]) then
        fromAge = searchParams["fromAge"]
    else
        fromAge = "-inf"
    end

    if (searchParams["toAge"]) then
        toAge = searchParams["toAge"]
    else
        toAge = "+inf"
    end

    if (searchParams["gender"]) then
        gender = searchParams["gender"]
    else
        gender = false
    end

    local visitIds
    -- если только диапазон - то просто упорядоченные визиты пользователя
    if (toDistance == false and country == false) then
        visitIds =  redis:zrangebyscore("user_visits:" .. user.id() ..":visited_at", fromDate , toDate)
        if (visitIds == false or visitIds == nil) then
            return {}
        end
        return visitIds
    end

    -- + дистанция
    local tmpkeydist
    if (toDistance ~= false) then
        local keyDistance = "user_visits:" .. user.id() .. ":distance"

        local VisitIdsForDistance = redis:zrangebyscore(keyDistance, "-inf", toDistance)
        if (VisitIdsForDistance == false or VisitIdsForDistance == nil) then
            return {}
        end
        tmpkeydist = "tmpkeydist_" .. math.random(1000000000)
        redis:sadd(tmpkeydist, unpack(VisitIdsForDistance));
    end

    local tmpkey = "tmpkey_" .. math.random(1000000000)
    local keyDate =  "user_visits:" .. user.id() .. ":visited_at"

    -- + страна
    if (country ~= false) then
        local keycountry = "user_visits:" .. user.id() .. ":country:" .. country

        if (toDistance ~= false) then
            redis:zinterstore(tmpkey, 3, keycountry, keyDate, tmpkeydist, "AGGREGATE", "MAX")
            redis:del(tmpkeydist)
        else
            redis:zinterstore(tmpkey, 2, keycountry, keyDate, "AGGREGATE", "MAX")
        end
        visitIds =  redis:zrangebyscore(tmpkey, fromDate , toDate)
    else
        redis:zinterstore(tmpkey, 2, keyDate, tmpkeydist, "AGGREGATE", "MAX")
        redis:del(tmpkeydist)
        visitIds =  redis:zrangebyscore(tmpkey, fromDate , toDate)
    end

    redis:del(tmpkey)


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

    function self.search(locationId)
        if is_identity(locationId) then else ngx.exit(404) end
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
            if (k == "fromAge") then
                if is_identity(v) then else ngx.exit(400) end
                searchParams["fromAge"] = tonumber(v)
            end
            if (k == "toAge") then
                if is_identity(v) then else ngx.exit(400) end
                searchParams["toAge"] = tonumber(v)
            end
            if (k == "gender") then
                if (v ~= "m" and v ~="f") then else ngx.exit(400) end
                searchParams["gender"] = v
            end
        end

        local redisIns = require "nginx.redis"
        local redis = redisIns:new()
        local ok, err = redis:connect("0.0.0.0", 6379)
        local location = createLocationFromRedisId(locationId, redis)

        if location then
            local visitIds = getVisitIds(location, searchParams, redis)

            local visit
            local sum = 0
            local count = 0
            for k,visitId in pairs(visitIds) do
                visit = createVisitFromRedisId(visitId, redis)
                count = count + 1
                sum = sum + visit.mark()
            end
            local avg = sum / count
            ngx.say('{ "avg": ' .. avg .. '}')


        else
            ngx.status = 404
            ngx.print("Not found!")
        end

    end

    -- return the instance
    return self
end