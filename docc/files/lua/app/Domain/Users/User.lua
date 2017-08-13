function User(id, birth_date, gender, first_name, last_name, email)
    -- the new instance
    local self = {
        id = id,
        birth_date = birth_date,
        gender = gender,
        first_name = first_name,
        last_name = last_name,
        email = email,
    }

    function self.toJson()
        -- todo кидать ошибку если пустой объект
        local cjson = require('cjson')
        return cjson.encode(userObjHashTable)
    end

    -- return the instance
    return self
end

function createUserFromRedisData(redisData)
    if (canCreateUserFromRedisData(redisData)) then
        local userObjHashTable = {};
        local propertyTemp;
        local isPropertyTemp = true;
        for k,v in pairs(redisData) do
            if isPropertyTemp then
                propertyTemp = v
                isPropertyTemp = false
            else
                userObjHashTable[propertyTemp] = v
                isPropertyTemp = true
            end
        end
        return User(userObjHashTable['id'], userObjHashTable["birth_date"], userObjHashTable["gender"], userObjHashTable["first_name"], userObjHashTable["last_name"], userObjHashTable["email"])
    else
        return false;
    end
end

function canCreateUserFromRedisData(redisData)
    return next(redisData) == nil
end