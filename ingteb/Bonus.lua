local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Bonus = class:new("Bonus", Common)

Bonus.system.Properties = {
    NumberOnSprite = {get = function(self) return self.Prototype.modifier end},
    SpriteType = { get = function(self) return "utility" end },
}

function Bonus:new(name, prototype, database)
    local self = self:adopt(self.system.BaseClass:new(prototype, database))
    self.Name = name
    self.UsePercentage = true

    function self:SortAll() end

    return self
end

return Bonus
