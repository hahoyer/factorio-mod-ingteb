require "core.debugSupport"
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("Amounts")

Class.system.Properties = {
    ActualValue = {get = function(self) dassert() end},
}

function Class:new(name, prototype, database)
    local self = self:adopt(self.system.BaseClass:new(prototype, database))
    self.Name = name
    self.SpriteType = "utility"
    self.UsedBy = Dictionary:new{}
    self.CreatedBy = Array:new{}
    self.Input = Array:new{}
    self.Output = Array:new{}
    self.UsePercentage = true

    function self:SortAll() end

    return self
end

return Class
