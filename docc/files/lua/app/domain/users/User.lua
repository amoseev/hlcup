function User(userTable)
    -- the new instance
    local self = {}

    local userTable = userTable

    local userObjHashTable = {}
    local isEmpty;

    if next(userTable) == nil then
        isEmpty = true
    else
        isEmpty = false

        local propertyTemp;
        local isPropertyTemp = true;
        for k,v in pairs(userTable) do
            if isPropertyTemp then
                propertyTemp = v
                isPropertyTemp = false
            else
                userObjHashTable[propertyTemp] = v
                isPropertyTemp = true
            end
        end
    end


    function self.isEmpty()
        return isEmpty
    end

    function self.toJson()
        -- todo кидать ошибку если пустой объект
        local cjson = require('cjson')
        return cjson.encode(userObjHashTable)
    end

    -- return the instance
    return self
end