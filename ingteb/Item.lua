local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local Goods = require("ingteb.Goods")
local UI = require("core.UI")
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
            if counts then
                local craftingCountText =
                    counts.Crafting > 0 and "(+" .. counts.Crafting .. ")" or ""
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
            local result = {Inventory = UI.Player.get_item_count(self.Name), Crafting = 0}
            local recipes = self.CreatedBy["crafting.crafting"]
            if recipes then
                result.Crafting = recipes --
                :Select(
                    function(recipe)
                        return UI.Player.get_craftable_count(recipe.Name)
                    end
                ) --
                :Maximum()
            end
            if result.Inventory > 0 or result.Crafting > 0 then return result end
        end,
    },

    SpecialFunctions = {
        get = function(self) --
            return Array:new{
                {
                    UICode = "--S l",
                    Action = function()
                        return {Selecting = self, Entity = self.Entity}
                    end,
                },
            }
        end,
    },

    IsRefreshRequired = {get = function(self) return {MainInventory = true} end},
}

function Item:new(name, prototype, database)
    local self = self:adopt(self.base:new(prototype or game.item_prototypes[name], database))
    self.SpriteType = "item"

    assert(release or self.Prototype.object_name == "LuaItemPrototype")

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
