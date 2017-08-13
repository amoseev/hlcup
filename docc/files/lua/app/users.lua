-- В ответе ожидается код 404, если сущности с таким идентификатором нет в данных.
--GET: /users/1
--{
--    "id": 1,
--    "email": "johndoe@gmail.com",
--    "first_name": "John",
--    "last_name": "Doe",
--    "gender": "m",
--    "birth_date": -1247184000
--}


local redis = require "nginx.redis"
local red = redis:new()
local ok, err = red:connect("0.0.0.0", 6379)
ok, err = red:incr("test")
ok, err = red:incr("test")
local res, err = red:get("test")
ngx.say("hits: ", res)
ngx.say("hits: ", res)

local args = ngx.req.get_uri_args()
for key, val in pairs(args) do
    if type(val) == "table" then
        ngx.say(key, ": ", table.concat(val, ", "))
    else
        ngx.say(key, ": ", val)
    end
end

