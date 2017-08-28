function User(id, birth_date, gender, first_name, last_name, email)
    -- the new instance
    local self = {
            fields = {
                id = tonumber(id),
                birth_date = tonumber(birth_date),
                gender = gender,
                first_name = first_name,
                last_name = last_name,
                email = email,
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

    function self.birth_date()
        return self.fields["birth_date"]
    end

    function self.set_birth_date(birth_date)
        if (is_identity(birth_date)) then
            self.fields["birth_date"] = birth_date
        else
            ngx.exit(400)
        end
    end

    function self.gender()
        return self.fields["gender"]
    end

    function self.first_name()
        return self.fields["first_name"]
    end

    function self.last_name()
        return self.fields["last_name"]
    end

    function self.email()
        return self.fields["email"]
    end

    function self.setFromTable(tableLocation)
        if (tableLocation["birth_date"]) then
            self.set_birth_date(tableLocation["birth_date"])
        end
        if (tableLocation["gender"]) then
            self.fields["gender"] = tableLocation["gender"]
        end
        if (tableLocation["first_name"]) then
            self.fields["first_name"] = tableLocation["first_name"]
        end
        if (tableLocation["last_name"]) then
            self.fields["last_name"] = tableLocation["last_name"]
        end
        if (tableLocation["email"]) then
            self.fields["email"] = tableLocation["email"]
        end
    end

    -- return the instance
    return self
end


function createUserFromRedisId(userId, redis)
    if (is_identity(userId)) then else ngx.exit(400) end

    local userRD, err = redis:hgetall("users:" .. userId)
    if err == nil then
        return createUserFromRedisData(userRD)
    else
        return false;
    end
end

function createUserFromRedisData(redisData)
    if (canCreateUserFromRedisData(redisData)) then
        local userObjHashTable = {};
        if(redisData["id"]) then
            userObjHashTable = redisData
        else
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
        end
        return User(userObjHashTable['id'], userObjHashTable["birth_date"], userObjHashTable["gender"], userObjHashTable["first_name"], userObjHashTable["last_name"], userObjHashTable["email"])
    else
        return false;
    end
end

function createUserFromTableParsedJson(tableUser)
    if (canCreateUserFromTableParsedJson(tableUser)) then
        return User(tableUser['id'], tableUser["birth_date"], tableUser["gender"], tableUser["first_name"], tableUser["last_name"], tableUser["email"])
    else
        return false;
    end
end


function canCreateUserFromRedisData(redisData)
    return next(redisData) ~= nil
end

function canCreateUserFromTableParsedJson(tableUser)
    local required = {"id", "birth_date", "gender", "first_name", "last_name", "email"}

    for key,field in pairs(required) do
        if (tableUser[field] == nil or tableUser[field] == "null" or isEmptyString(tableUser[field])) then
            return false
        end
    end

    return true
end

function saveUserToRedis(user, redis)
    if user ~= false then
        local key = "users:" ..  user.id()
        redis:hmset(key, "id", user.id(), "birth_date",user.birth_date(), "gender", user.gender(), "first_name",user.first_name(),  "last_name", user.last_name(), "email",user.email())
    end
end