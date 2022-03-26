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
            return self.Database.ItemsForFuelCategory[self.Name] --
            :Select(function(item) return self.Database:GetItem(nil, item) end)
        end,
    },
    SpriteName = {
        cache = true,
        get = function(self)
            local prototype = self.Prototype
            local result = "tooltip-category-" .. self.Name
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

    Burners = {
        cache = true,
        get = function(self)
            local result = Array:new(self.Database.EntitiesForBurnersFuel[self.Name]) --
            :Select(function(workerName) return self.Database:GetEntity(workerName) end)
            result:Sort(function(a, b) return a:IsBefore(b) end)
            return result
        end,
    },

    Properties = {
        cache = true,
        get = function(self) return Array:new{self.Fuels, self.Burners}:ConcatMany() end,
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
    self.Name = name
    self.SpriteType = "fuel-category"

    function self:SortAll() end

    return self

end

return FuelCategory

