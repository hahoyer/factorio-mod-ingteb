local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("BurningRecipe", Common)

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
    Time = {
        cache = true,
        get = function(self)
            local energyUsagePerSecond = self.Category.EnergyUsagePerSecond
            if energyUsagePerSecond then return self.FuelValue / energyUsagePerSecond end
        end,
    },

}

function Class:new(name, prototype, database)
    dassert(name == nil)
    dassert(prototype)
    local self = self:adopt(self.system.BaseClass:new(prototype, database))
    self.Name = prototype.name
    self.IsFluid = prototype.object_name == "LuaFluidPrototype"
    self.IsHidden = true
    self.IsRecipe = true
    self.SpriteType = self.IsFluid and "fluid" or "item"

    local categoryName = self.IsFluid and "fluid-burning.fluid" or "burning."
                             .. prototype.fuel_category
    self.Category = self.Database:GetCategory(categoryName)
    self.FuelValue = prototype.fuel_value
    self.TypeStringForLocalisation = "ingteb-utility.title-burning-recipe"

    self.RawInput = {{type = self.IsFluid and "fluid" or "item", amount = 1, name = prototype.name}}
    local output = not self.IsFluid and prototype.burnt_result
    if output then
        self.RawOutput = {{type = output.type, amount = 1, name = output.name}}
    else
        self.RawOutput = {}
    end
    function self:IsBefore(other)
        if self == other then return false end
        return self.OrderValue < other.OrderValue
    end

    function self:SortAll() end

    return self
end

return Class
