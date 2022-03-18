local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local FuelCategory = class:new("FuelCategory", Common)

FuelCategory.system.Properties = {
    Fuels = {
        cache = true,
        get = function(self)
            return self.Database.ItemsForFuelCategory[self.Prototype.name] --
            :Select(function(item) return self.Database:GetItem(nil, item) end)
        end,
    },
    SpriteName = {
        cache = true,
        get = function(self)
            local prototype = self.Prototype
            local result = "tooltip-category-" .. prototype.name
            if game.is_valid_sprite_path(result) then return result end
            local item = self.Fuels:Top()
            if item then
                result = "item." .. self.Fuels:Top(false).Prototype.name
            return result
            end

            log {
                "mod-issue.fuel-category-empty",
                prototype.localised_name,
                "fuel_category." .. prototype.name,
            }
            return "utility/missing_icon"

        end,
    },

}

function FuelCategory:new(name, prototype, database)
    dassert(name)

    local self = self:adopt(
        self.system.BaseClass:new(
            prototype or game.fuel_category_prototypes[name], database
        )
    )

    dassert(self.Prototype.object_name == "LuaFuelCategoryPrototype")

    self.Workers = Array:new()
    self.SpriteType = "fuel-category"

    function self:SortAll() end

    return self

end

return FuelCategory

