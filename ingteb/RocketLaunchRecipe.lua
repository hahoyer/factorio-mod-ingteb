local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("RocketLaunchRecipe", Common)

Class.system.Properties = {
    OrderValue = {
        cache = true,
        get = function(self)
            return self.TypeOrder --
            .. " R R " --
            .. self.Prototype.group.order --
            .. " " .. self.Prototype.subgroup.order --
            .. " " .. self.Prototype.order
        end,
    },
}

function Class:new(name, prototype, database)
    local self = self:adopt(self.system.BaseClass:new(prototype, database))
    self.Name = name
    self.SpriteType = "item"
    self.Time = 1
    self.IsRecipe = true
    self.Category = self.Database:GetCategory("rocket-launch.rocket-launch")
    self.TypeStringForLocalisation = "ingteb-utility.title-rocket-launch-recipe"

    self.RawInput = {
        {type = "item", amount = self.Prototype.default_request_amount, name = self.Prototype.name},
    }

    self.RawOutput = self.Prototype.rocket_launch_products

    function self:IsBefore(other)
        if self == other then return false end
        return self.OrderValue < other.OrderValue
    end

    function self:SortAll() end

    return self
end

return Class
