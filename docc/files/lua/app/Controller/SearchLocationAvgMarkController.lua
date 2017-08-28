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
        local ok, err = redis:connect("0.0.0.0", 637           9)
        local location = createLocationFromRedisId(locationId, redis)

        if location then
            local visitIds = getVisitIds(user, searchParams, redis)
            local visit_responses = cjson.decode('[]');
            local visit, location
            for k,visitId in pairs(visitIds) do
                visit = createVisitFromRedisId(visitId, redis)
                location = createLocationFromRedisId(visit.location(), redis)

                visit_responses[k] = {visit_id = visit.id(), location=location.id(), mark = visit.mark(), visited_at= visit.visited_at(),  place = location.place(), distance = location.distance(), country = location.country()}
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