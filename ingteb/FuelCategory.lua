local Constants = require("Constants")
local Helper = require "ingteb.Helper"

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local Common = require("ingteb.Common")
local class = require("core.class")

local FuelCategory = class:new("FuelCategory", Common)

FuelCategory.system.Properties = {
    SpriteType = { get = function(self) return "fuel-category" end },
    GameType = { get = function(self) return "fuel_category" end },
    Fuels = { get = function(self) return self:GetBackLinkArray("fuel_category", "item") end, },
    SpriteName = {
        cache = true,
        get = function(self)
            local prototype = self.Prototype
            local result = "tooltip-category-" .. self.Name
            if game.is_valid_sprite_path(result) then return result end
            local item = self.Fuels:Top()
            if item then
                return item.SpriteName
            end

            log {
                "mod-issue.fuel-category-empty",
                prototype.localised_name,
                "Burning." .. prototype.name,
            }
            return "utility/missing_icon"

        end,
    },

    Burners = {
        cache = true,
        get = function(self)
            local result = Array:new(self.Database.BackLinks.EntitiesForBurnersFuel[self.Name])--
                :Select(function(workerName) return self.Database:GetEntity(workerName) end)
            result:Sort(function(a, b) return a:IsBefore(b) end)
            return result
        end,
    },

    UsefulLinks = {
        cache = true,
        get = function(self) return Array:new { self.Fuels, self.Burners } end,
    },

}

function FuelCategory:new(name, prototype, database)
    dassert(name or prototype)

    if name == "fluid" and not prototype then
        prototype = Helper.CreatePrototypeProxy {
            type = "fuel-category",
            name = name,
        }
    end

    local self = self:adopt(
        self.system.BaseClass:new(
            prototype or game.fuel_category_prototypes[name], database
        )
    )

    function self:SortAll() end

    return self

end

return FuelCategory
