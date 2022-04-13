local class = require("core.classclass")
local ValueCache = require "core.ValueCache"
local Class = class:new "PlayerValueCache"

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
    instance.Player = {}
    return instance
end

function Class:get_IsValid() return self.Player[self.Client.Player.name] ~= nil end

function Class:set_IsValid(value)
    if value == self:get_IsValid() then return end
    if value then
        self:Ensure()
    else
        self:Reset()
    end
end

function Class:get_Value()
    self:Ensure()
    return self.Player[self.Client.Player.name].Value
end

function Class:Ensure()
    local client = self.Client
    local player = client.Player
    if self.Player[player.name] then return end
    self.Player[player.name] = {Value = rawget(self, "getValueFunction")(self.Client)}
end

function Class:Reset()
    local client = self.Client
    local player = client.Player
    self.Player[player.name] = nil
end

return Class
