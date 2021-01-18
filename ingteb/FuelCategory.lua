local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local FuelCategory = class:new("FuelCategory", Common)

FuelCategory.property = {
    Fuels = {
        cache = true,
        get = function(self)
            return self.Database.ItemsForFuelCategory[self.Prototype.name] --
            :Select(function(item) return self.Database:GetItem(nil, item) end)
        end,
    },
}

function FuelCategory:new(name, prototype, database)
    assert(name)

    local self = self:adopt(
        self.base:new(prototype or game.fuel_category_prototypes[name], database)
    )

    assert(self.Prototype.object_name == "LuaFuelCategoryPrototype")

    self.Workers = Array:new()
    self.SpriteType = "fuel-category"

    function self:SortAll() end

    return self

end

return FuelCategory

