local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require "ingteb.RecipeCommon"
local class = require("core.class")

local Class = class:new("RocketLaunchRecipe", Common)

Class.system.Properties = {
    Time = {cache = true, get = function(self) return 1.0 / self.Category.Speed end},
}

function Class:new(name, prototype, database)
    dassert(name == nil)
    dassert(prototype)
    local outputPrototype = game.item_prototypes[prototype.rocket_launch_products[1].name]
    local self = self:adopt(self.system.BaseClass:new(outputPrototype, database))
    self.Name = prototype.name
    self.SpriteType = "item"
    self.IsHidden = true
    self.Category = self.Database:GetCategory("rocket-launch.rocket-launch")
    self.TypeStringForLocalisation = "ingteb-utility.title-rocket-launch-recipe"

    self.RawInput = {
        {type = "item", amount = prototype.default_request_amount, name = prototype.name},
    }

    self.RawOutput = prototype.rocket_launch_products

    function self:IsBefore(other)
        if self == other then return false end
        return self.OrderValue < other.OrderValue
    end

    function self:SortAll() end

    return self
end

return Class
