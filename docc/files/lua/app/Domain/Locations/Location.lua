function Location(id, distance, city, place, country)
    -- the new instance
    local self = {
        fields = {
            id = id,
            distance = distance,
            city = city,
            place = place,
            country = country
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

    function self.distance()
        return self.fields["distance"]
    end

    function self.city()
        return self.fields["city"]
    end

    function self.place()
        return self.fields["place"]
    end

    function self.country()
        return self.fields["country"]
    end

    -- return the instance
    return self
end

function createLocationFromRedisId(locationId, redis)

    local visitRD, err = redis:hgetall("locations:" .. locationId)

    if err == nil then
        return createLocationFromRedisData(visitRD)
    else
        return false;
    end
end


function createLocationFromRedisData(redisData)
    if (canCreateLocationFromRedisData(redisData)) then
        local locationObjHashTable = {};
        local propertyTemp;
        local isPropertyTemp = true;
        for k,v in pairs(redisData) do
            if isPropertyTemp then
                propertyTemp = v
                isPropertyTemp = false
            else
                locationObjHashTable[propertyTemp] = v
                isPropertyTemp = true
            end
        end
        return Location(locationObjHashTable['id'], locationObjHashTable["distance"], locationObjHashTable["city"], locationObjHashTable["place"], locationObjHashTable["country"])
    else
        return false;
    end
end

function createLocationFromTableParsedJson(tableLocation)
    if (canCreateLocationFromTableParsedJson(tableLocation)) then
        return Location(tableLocation['id'], tableLocation["distance"], tableLocation["city"], tableLocation["place"], tableLocation["country"])
    else
        return false;
    end
end


function canCreateLocationFromRedisData(redisData)
    return next(redisData) ~= nil
end

function canCreateLocationFromTableParsedJson(tableLocation)
    local required = {"id", "distance", "city", "place", "country"}

    for key,field in pairs(required) do
        if tableLocation[field] == nil then
            return false
        end
    end

    return true
end

function saveLocationToRedis(location, redis)
    if location ~= false then
        local key = "locations:" ..  location.id()
        redis:hmset(key, "id", location.id(), "distance",location.distance(), "city", location.city(), "place",location.place(),  "country", location.country())
    end

    -- todo При смене странцы локации изменить
    -- key = "user_visits:" ..  visit.user().. ":country:" .. location.country()
    -- docc/files/lua/app/Domain/Visits/Visit.lua:137
end