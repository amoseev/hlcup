--
-- Получение списка мест, которые посетил пользователь: /users/<id>/visits.
-- В теле ответа ожидается структура {"visits": [ ... ]}, отсортированная по возрастанию дат, или ошибка 404/400. Подробнее - в примере.
-- Возможные GET-параметры:
-- fromDate - посещения с visited_at > fromDate
-- toDate - посещения с visited_at < toDate
-- country - название страны, в которой находятся интересующие достопримечательности
-- toDistance - возвращать только те места, у которых расстояние от города меньше этого параметра
--

function SearchUserVisitsController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
    }

    function self.search(userId)
        if is_identity(userId) then else ngx.exit(400) end

        local redisIns = require "nginx.redis"
        local redis = redisIns:new()
        local ok, err = redis:connect("0.0.0.0", 6379)
        local userRD, err = redis:hgetall("users:" .. userId)

        if err == nil then
            require "app.Domain.Users.User"
            require "app.Domain.Locations.Location"
            require "app.Domain.Visits.Visit"

            if canCreateUserFromRedisData(userRD) then
                local  user = createUserFromRedisData(userRD)

                local visitIds = redis:zrangebyscore("user_visits:" .. user.id() ..":visited_at", "-inf", "+inf")

                local visit_responses = {};

                local visit, location
                for k,visitId in pairs(visitIds) do
                    visit = createVisitFromRedisId(visitId, redis)
                    location = createLocationFromRedisId(visit.location(), redis)
                    visit_responses[k] = {mark = 2, visited_at= visit.visited_at(),  place = location.place()}
                end

                local cjson = require('cjson')
                local content= cjson.encode({visits = visit_responses})
                ngx.say(content)
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

    -- return the instance
    return self
end