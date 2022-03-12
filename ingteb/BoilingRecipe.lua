local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local function CalculateHeaterValues(prototype)
    local fluidBoxes = Array:new(prototype.fluidbox_prototypes)
    local inBox --
    = fluidBoxes --
    :Where( --
          function(box)
            return box.filter
                       and (box.production_type == "input" or box.production_type == "input-output")
        end
      ) --
    :Top(false, false) --
    .filter

    local outBox = fluidBoxes --
    :Where(function(box) return box.filter and box.production_type == "output" end) --
    :Top(false, false) --
    .filter

    local inEnergy = (outBox.default_temperature - inBox.default_temperature) * inBox.heat_capacity
    local outEnergy = (prototype.target_temperature - outBox.default_temperature)
                          * outBox.heat_capacity

    local amount = 60 * prototype.max_energy_usage / (inEnergy + outEnergy)

    return {amount = amount, input = inBox.name, output = outBox.name}

end

local Class = class:new("BoilingRecipe", Common)

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
    self.SpriteType = "entity"
    self.Time = 1
    self.IsRecipe = true
    self.Category = self.Database:GetCategory("boiling." .. name)
    self.TypeStringForLocalisation = "ingteb-utility.title-boiling-recipe"

    local recipe = CalculateHeaterValues(self.Prototype)
    self.RawInput = {{type = "fluid", amount = recipe.amount, name = recipe.input}}
    self.RawOutput = {{type = "fluid", amount = recipe.amount, name = recipe.output}}

    function self:IsBefore(other)
        if self == other then return false end
        return self.OrderValue < other.OrderValue
    end

    function self:SortAll() end

    return self
end

return Class
