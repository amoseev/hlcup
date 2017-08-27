require "vendor.functions"
require "app.Domain.Users.User"
require "app.Domain.Locations.Location"
require "app.Domain.Visits.Visit"

local function getPostBody()
    for key, val in pairs(ngx.req.get_post_args()) do
        return key
    end
end


local router = require 'vendor.router'
local r = router.new()

r:match({
    GET = {
        ["/users/:id"] = function(params)
            require 'app.Controller.UserController'
            local controller = UserController()
            controller.get(params.id)
        end,
        ["/locations/:id"] = function(params)
            require 'app.Controller.LocationController'
            local controller = LocationController()
            controller.get(params.id)
        end,
        ["/visits/:id"] = function(params)
            require 'app.Controller.VisitController'
            local controller = VisitController()
            return controller.get(params.id, getPostBody())
        end,

        -- поиск визитов юзера
        ["/users/:id/visits"] = function(params)
            require 'app.Controller.SearchUserVisitsController'
            local controller = SearchUserVisitsController()
            return controller.search(params.id)
        end,
        -- поиск средней оценки локации
        ["/locations/:id/avg"] = function(params)
            require 'app.Controller.SearchLocationAvgMarkController'
            local controller = SearchLocationAvgMarkController()
            return controller.search(params.id)
        end
    },
    POST = {
        ["/users/new"] = function(params)
            require 'app.Controller.UserController'
            local controller = UserController()
            return controller.update("new", getPostBody())
        end,
        ["/users/:id"] = function(params)
            require 'app.Controller.UserController'
            local controller = UserController()
            return controller.update(params.id, getPostBody())
        end,
        ["/locations/new"] = function(params)
            require 'app.Controller.LocationController'
            local controller = LocationController()
            return controller.update("new", getPostBody())
        end,
        ["/locations/:id"] = function(params)
            require 'app.Controller.LocationController'
            local controller = LocationController()
            return controller.update(params.id, getPostBody())
        end,
        ["/visits/new"] = function(params)
            require 'app.Controller.VisitController'
            local controller = VisitController()
            return controller.update("new", getPostBody())
        end,
        ["/visits/:id"] = function(params)
            require 'app.Controller.VisitController'
            local controller = VisitController()
            return controller.update(params.id, getPostBody())
        end
    }
})


local postargs = {}
if (ngx.var.request_method == 'POST') then
    postargs = ngx.req.get_post_args()
end


local ok, errmsg = r:execute(ngx.var.request_method,
    ngx.var.uri,
    ngx.req.get_uri_args(), -- all these parameters
    postargs, -- will be merged in order
    { other_arg = 1 } -- into a single "params" table))
)

if ok then
    --
else
    ngx.status = 404
    ngx.print("Not found!")
    -- TODO REMOVE
    var_dump( errmsg)
    ngx.exit(404)
end

