function vd_string(o)
    return '"' .. tostring(o) .. '"'
end

function vd_recurse(o, indent)
    if indent == nil then indent = '' end
    local indent2 = indent .. '  '
    if type(o) == 'table' then
        local s = indent .. '{' .. '\n'
        local first = true
        for k,v in pairs(o) do
            if first == false then s = s .. ', \n' end
            if type(k) ~= 'number' then k = vd_string(k) end
            s = s .. indent2 .. '[' .. k .. '] = ' .. vd_recurse(v, indent2)
            first = false
        end
        return s .. '\n' .. indent .. '}'
    else
        return vd_string(o)
    end
end

function var_dump(...)
    local args = {...}
    if #args > 1 then
        var_dump(args)
    else
        ngx.say(vd_recurse(args[1]))
    end
end

local router = require 'vendor.router'
local r = router.new()

r:match({
GET = {
  ["/users/:id"]   = function(params)
      require 'app.Controller.UserController'
      local controller = UserController()
      controller.get(params.id)
  end,
  ["/users/:id/visits"] = function(params) ngx.print('user visits for user with id = ' .. params.id) end
},
POST = {
  ["/users/:id"] = function(params)
    ngx.print('user update for user with id = ' .. params.id)
  end
}
})


local postargs ={}
if (ngx.var.request_method == 'POST') then
    postargs = ngx.req.get_post_args()
end


local ok, errmsg = r:execute(
    ngx.var.request_method,
    ngx.var.request_uri,
    ngx.req.get_uri_args(),  -- all these parameters
    postargs, -- will be merged in order
    {other_arg = 1} -- into a single "params" table
)


if ok then
    --
else
    ngx.print("Not found!")
    -- TODO REMOVE
    ngx.log(ngx.ERROR, errmsg)
    ngx.exit(404)
end

