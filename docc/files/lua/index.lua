local router = require 'vendor.router'
local r = router.new()

r:match({
GET = {
  ["/users/:id"]   = function(params) ngx.print('user with id = ' .. params.id) end,
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
    ngx.status = 200
else
    ngx.status = 404
    ngx.print("Not found!")
    -- TODO REMOVE
    ngx.log(ngx.ERROR, errmsg)
end
