local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Goods = require("ingteb.Goods")
local class = require("core.class")

function FormatEnergy(value)
    if value < 0 then return "-" .. FormatEnergy(-value) end
    if value < 1000 then return value .. "J" end
    value = value / 1000
    if value < 1000 then return value .. "kJ" end
    value = value / 1000
    if value < 1000 then return value .. "MJ" end
    value = value / 1000
    if value < 1000 then return value .. "GJ" end
    value = value / 1000
    if value < 1000 then return value .. "TJ" end
    value = value / 1000
    return value .. "PJ"

end

local Item = class:new("Item", Goods)

Item.property = {
    Entity = {
        cache = true,
        get = function(self)
            if self.Prototype.place_result then
                return self.Database:GetEntity(self.Prototype.place_result.name)
            end
        end,
    },

    ResearchingTechnologies = {
        cache = true,
        get = function(self)
            local list = self.Database.ResearchingTechnologyForItems[self.Prototype.name]
            if not list then return end
            return list:Select(
                function(prototype)
                    return self.Database:GetTechnology(nil, prototype)
                end
            )
        end,
    },

    AdditionalHelp = {
        get = function(self)
            local result = self.inherited.Item.AdditionalHelp.get(self) --

            if self.Prototype.fuel_acceleration_multiplier
                and self.Prototype.fuel_acceleration_multiplier ~= 1 then
                result:Append{
                    "",
                    {"description.fuel-acceleration"},
                    " " .. self.Prototype.fuel_acceleration_multiplier,
                }
            end

            local counts = self.PlayerCounts
            if counts and (counts.Inventory > 0 or counts.Crafting > 0) then
                local craftingCountText = counts.Crafting > 0 and "(+" .. counts.Crafting .. ")"
                                              or ""
                result:Append(
                    self.Database:GetEntity("character").RichTextName .. ": " .. counts.Inventory
                        .. craftingCountText
                )
            end

            return result
        end,
    },

    PlayerCounts = {
        get = function(self)
            local crafting, recipe = self.Database:GetCraftableCount(self)

            local result = {
                Inventory = self.Database:GetCountInInventory(self) or 0,
                Hand = self.Database:GetCountInHand(self) or 0,
                Crafting = crafting or 0,
                Recipe = recipe,
            }
            result.Available = result.Inventory + result.Hand

            return result
        end,
    },

    SpecialFunctions = {
        get = function(self) --
            local count, recipe = self.Database:GetCraftableCount(self)
            local result = self.inherited.Item.SpecialFunctions.get(self)
            return result:Concat{
                {
                    UICode = "--S l",
                    Action = function(self)
                        return {Selecting = self, Entity = self.Entity}
                    end,
                },
                {
                    UICode = "A-- l",
                    HelpText = "controls.craft",
                    IsAvailable = function(self) return count and count > 0 end,
                    Action = function(self)
                        return {HandCrafting = {count = 1, recipe = recipe.Name}}
                    end,
                },
                {
                    UICode = "A-- r",
                    HelpText = "controls.craft-5",
                    IsAvailable = function(self) return count and count > 0 end,
                    Action = function(self)
                        return {HandCrafting = {count = 5, recipe = recipe.Name}}
                    end,
                },
                {
                    UICode = "--S l",
                    HelpText = "controls.craft-all",
                    IsAvailable = function(self) return count and count > 0 end,
                    Action = function()
                        return {HandCrafting = {count = count, recipe = recipe.Name}}
                    end,
                },
            }
        end,
    },

    IsRefreshRequired = {get = function(self) return {MainInventory = true} end},
}

function Item:new(name, prototype, database)
    local self = self:adopt(self.system.base:new(prototype or game.item_prototypes[name], database))
    self.SpriteType = "item"

    dassert(self.Prototype.object_name == "LuaItemPrototype")

    if self.Prototype.fuel_category then
        self.Fuel = {
            Category = self.Database:GetFuelCategory(self.Prototype.fuel_category),
            Value = self.Prototype.fuel_value,
            Acceleration = self.Prototype.fuel_acceleration_multiplier,
        }

    end

    return self

end

return Item
