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

function SearchUserVisitsController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
    }

    function self.search(userId)

        if is_identity(userId) then else ngx.exit(404) end

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
                searchParams["country"] = v
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
            local fromDate
            if (searchParams["fromDate"]) then
                fromDate = searchParams["fromDate"]
            else
                fromDate = "-inf"
            end

            local toDate
            if (searchParams["toDate"]) then
                toDate = searchParams["toDate"]
            else
                toDate = "+inf"
            end

            local visitIds = redis:zrangebyscore("user_visits:" .. user.id() ..":visited_at", fromDate , toDate)


            local visit_responses = {};
            local visit, location
            for k,visitId in pairs(visitIds) do
                visit = createVisitFromRedisId(visitId, redis)
                location = createLocationFromRedisId(visit.location(), redis)
                visit_responses[k] = {mark = visit.mark(), visited_at= visit.visited_at(),  place = location.place()}
            end

            local cjson = require('cjson')
            ngx.say(cjson.encode({visits = visit_responses}))
        else
            ngx.status = 404
            ngx.print("Not found!")
        end

    end

    -- return the instance
    return self
end