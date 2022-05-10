local Constants = require "Constants"
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Goods = require("ingteb.Goods")
local class = require("core.class")

local Item = class:new("Item", Goods)

Item.system.Properties = {
    SpriteType = { get = function(self) return "item" end },
    BackLinkName = { get = function(self) return "item" end },
    Entity = {
        cache = true,
        get = function(self)
            if self.Prototype.place_result then
                return self.Database:GetEntity(self.Prototype.place_result.name)
            end
        end,
    },

    UsefulLinks = {
        cache = true,
        get = function(self)
            local result = Array:new {}

            if self.Fuel then result:Append(Array:new { self.Fuel.Category }) end
            if self.Entity then result:AppendMany(self.Entity.UsefulLinks) end

            local moduleTargets = self.ModuleTargets--
                :Where(function(value) return value end)--
                :ToArray(function(_, module) return module end)
            if moduleTargets:Any() then result:Append(moduleTargets) end
            return result
        end,
    },

    ResearchingTechnologies = {
        cache = true,
        get = function(self)
            local list = self.BackLinks.
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
                result:Append {
                    "",
                    { "description.fuel-acceleration" },
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

            if self.ModuleEffectsHelp then
                result:AppendMany(self.ModuleEffectsHelp)
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
            return result:Concat {
                {
                    UICode = "-C- l",
                    HelpTextTag = "",
                    HelpTextItems = { "[img=color_picker_white]", { "controls.smart-pipette" } },
                    Action = function(self)
                        return { Selecting = self, Entity = self.Entity }
                    end,
                },
                {
                    UICode = "A-- l",
                    HelpTextTag = "controls.craft",
                    IsAvailable = function(self) return count and count > 0 end,
                    Action = function(self)
                        return { HandCrafting = { count = 1, recipe = recipe.Name } }
                    end,
                },
                {
                    UICode = "A-- r",
                    HelpTextTag = "controls.craft-5",
                    IsAvailable = function(self) return count and count > 0 end,
                    Action = function(self)
                        return { HandCrafting = { count = 5, recipe = recipe.Name } }
                    end,
                },
                {
                    UICode = "--S l",
                    HelpTextTag = "controls.craft-all",
                    IsAvailable = function(self) return count and count > 0 end,
                    Action = function()
                        return { HandCrafting = { count = count, recipe = recipe.Name } }
                    end,
                },
            }
        end,
    },

    IsRefreshRequired = { get = function(self) return { MainInventory = true } end },

    ModuleEffectsHelp = {
        cache = true,
        get = function(self)
            local result = Array:new()
            local prototype = self.Prototype
            for name, effect in pairs(prototype.module_effects or {}) do
                result:Append(self.Database:GetModuleEffect(name):GetEffectHelp(effect))

            end
            return result
        end,
    },

    ModuleTargets = {
        cache = true,
        get = function(self)
            local result = Dictionary:new()
            local prototype = self.Prototype
            for name in pairs(prototype.module_effects or {}) do
                local entities = self.Database.BackLinks.EntitiesForModuleEffects[name]
                if entities then
                    entities:Select(
                        function(entityPrototype)
                        local entity = self.Database:GetEntity(nil, entityPrototype)
                        if result[entity] ~= false then
                            local modules = entity.Modules
                            result[entity] = modules[self]
                        end
                    end
                    )
                end
            end
            return result
        end,
    },
}

function Item:new(name, prototype, database)
    local self = self:adopt(
        self.system.BaseClass:new(
            prototype or game.item_prototypes[name], database
        )
    )

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
