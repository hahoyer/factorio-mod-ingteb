local class = require("core.classclass")

local Class = class:new("ValueCache")

Class.system.Properties = {
    IsValid = {
        get = function(self) return self:get_IsValid() end,
        set = function(self, value) self:set_IsValid(value) end,
    },
    Value = {get = function(self) return self:get_Value() end},
}

function Class:new(client, getValueFunction)
    local instance = self:adopt{getValueFunction = getValueFunction}
    instance.Client = client
    return instance
end

function Class:get_Value()
    self:Ensure()
    return self.value
end

function Class:get_IsValid() return self.isValid end

function Class:set_IsValid(value)
    if value == self:get_IsValid() then return end
    if value then
        self:Ensure()
    else
        self:Reset()
    end
end

function Class:Ensure()
    if not self.isValid then
        self.value = rawget(self, "getValueFunction")(self.Client)
        self.isValid = true
    end
end

function Class:Reset()
    if self.isValid then
        self.value = nil
        self.isValid = false
    end
end

return Class
