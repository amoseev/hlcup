function userController()
    -- the new instance
    local self = {
        -- public fields go in the instance table
        public_field = 0
    }

    function self.get(userId)
        ngx.say(userId)
    end

    -- return the instance
    return self
end
