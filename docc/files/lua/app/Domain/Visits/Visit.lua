function Visit(id, user, location, visited_at, mark)
    -- the new instance
    local self = {
        fields = {
            id = id,
            user = user,
            location = location,
            visited_at = visited_at,
            mark = mark
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

    -- return the instance
    return self
end

function createVisitFromRedisData(redisData)
    if (canCreateVisitFromRedisData(redisData)) then
        local visitObjHashTable = {};
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
        if tableVisit[field] == nil then
            return false
        end
    end

    return true
end

function saveVisitToRedis(visit, redis)
    if visit ~= false then
        local key = "visits:" ..  visit.id()
        redis:hmset(key, "id", visit.id(), "user",visit.user(), "location", visit.location(), "visited_at",visit.visited_at(),  "mark", visit.mark())
    end
end