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

}

function Class:new(name, prototype, database)
    local self = self:adopt(self.system.BaseClass:new(prototype, database))
    self.Name = name
    self.Time = 1
    self.IsRecipe = true
    self.Category = self.Database:GetCategory("burning." .. prototype.fuel_category)
    self.TypeStringForLocalisation = "ingteb-utility.title-burning-recipe"

    local input = self.Prototype
    self.RawInput = {{type = input.type, amount = 1, name = input.name}}
    local output = self.Prototype.burnt_result
    self.RawOutput = {{type = output.type, amount = 1, name = output.name}}

    function self:IsBefore(other)
        if self == other then return false end
        return self.OrderValue < other.OrderValue
    end

    function self:SortAll() end

    return self
end

return Class
