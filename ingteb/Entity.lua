local Constants = require("Constants")
local Number = require "core.Number"
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local RequiredThings = require("ingteb.RequiredThings")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("Entity", Common)

Class.system.Properties = {
    SpriteType = { get = function(self) return "entity" end },
    BackLinkType = { get = function(self) return "entity" end },
    TypeStringForLocalisation = { get = function(self) return "ingteb-type-name.entity" end },
    UsedBy = {
        cache = true,
        get = function(self) return self.Database:GetUsedByRecipes(self.Prototype) end,
    },

    CreatedBy = {
        cache = true,
        get = function(self) return self.Database:GetCreatedByRecipes(self.Prototype) end,
    },

    SpriteName = {
        get = function(self)
            -- special entity for handmining
            if self.Name == "(hand-miner)" then return "technology/steel-axe" end
            return self.system.Inherited.Entity.SpriteName.get(self)
        end,
    },

    AdditionalHelp = {
        get = function(self)
            local result = self.system.Inherited.Entity.AdditionalHelp.get(self) --

            local maximal = self.MaxinmalEnergyConsumption
            if maximal then
                result:Append {
                    "",
                    { "description.max-energy-consumption" },
                    " " .. Number:new(maximal).Format3Digits .. "W",
                }
            end
            local minimalConsumption = self.MaxinimalEnergyConsumption
            if minimalConsumption then
                result:Append {
                    "",
                    { "description.min-energy-consumption" },
                    " " .. Number:new(minimalConsumption).Format3Digits .. "W",
                }
            end

            return result
        end,
    },

    -- ClickTarget = {
    --    get = function(self) return self.Item and self.Item.ClickTarget or self.CommonKey end,
    -- },

    Item = {
        cache = true,
        get = function(self)
            local place = self.Prototype.items_to_place_this
            if not place or #place == 0 then return end
            -- todo: present multiple items_to_place_this
            return self.Database:GetItem(place[1].name)
        end,
    },

    IsResource = { get = function(self) return false end },

    -- not used at the moment
    EnergySourceProperties = {
        cache = true,
        get = function(self)
            local data = self.Prototype.electric_energy_source_prototype
                or self.Prototype.fluid_energy_source_prototype
                or self.Prototype.heat_energy_source_prototype
                or self.Prototype.void_energy_source_prototype
            if data then --
                return --
            end
        end,
    },

    MaximalEnergyConsumption = {
        cache = true,
        get = function(self)
            local prototype = self.Prototype
            local usage = prototype.max_energy_usage
            if not usage then return end

            local result = usage * 60
            if prototype.burner_prototype and prototype.burner_prototype.effectivity and prototype.burner_prototype.effectivity ~= 1 then
                result = result / prototype.burner_prototype.effectivity
            end
            return result
        end,
    },

    MinimalEnergyConsumption = {
        cache = true,
        get = function(self)
            local prototype = self.Prototype
            local usage = prototype.min_energy_usage
            if not usage then return end

            local result = usage * 60
            if prototype.burner_prototype and prototype.burner_prototype.effectivity and prototype.burner_prototype.effectivity ~= 1 then
                result = result / prototype.burner_prototype.effectivity
            end
            return result
        end,
    },

    FuelCategories = {
        cache = true,
        get = function(self)
            return self.Categories--
                :Where(
                    function(category)
                    return category.Domain == "burning" or category.Domain == "fluid-burning"
                end
                )--
                :ToArray(
                    function(category)
                    local name = category.Domain == "fluid-burning" and "fluid" or category.SubName
                    return self.Database:GetFuelCategory(name)
                end
                )
        end,
    },

    UsefulLinks = { get = function(self) return Array:new { self.FuelCategories, self.Modules, } end, },

    Categories = {
        cache = true,
        get = function(self)
            local xreturn = Dictionary:new(self.Database.BackLinks.WorkersForCategory)--
                :Where(
                    function(workers)
                    return workers and workers:Any(
                        function(_, name) return name == self.Prototype.name end
                    )
                end
                )--
                :Select(function(_, categoryName) return self.Database:GetCategory(categoryName) end)
            return xreturn
        end,
    },

    AllRecipes = {
        cache = true,
        get = function(self)
            return self.Categories--
                :Select(function(category) return category.AllRecipes end)--
                :Where(function(recipes) return recipes:Any() end) --
        end,
    },
    PossibleRecipes = {
        cache = true,
        get = function(self)
            return self.Categories--
                :Select(function(category) return category.PossibleRecipes end)--
                :Where(function(recipes) return recipes:Any() and recipes[1].Category.Workers:Any() end)
        end,
    },
    Recipes = {
        get = function(self)
            local playerSettings = settings.get_player_settings(self.Player)
            if playerSettings["ingteb_show-impossible-recipes"].value then
                return self.AllRecipes
            else
                return self.PossibleRecipes
            end
        end,
    },

    SpecialFunctions = {
        get = function(self)
            local inherited = self.system.Inherited.Entity.SpecialFunctions.get(self)
            if not self.Item then return inherited end
            local result = Array:new {
                {
                    UICode = "--- l", --
                    Action = function(self) return { Presenting = self.Item } end,
                },
                {
                    UICode = "-C- l",
                    HelpTextTag = "",
                    HelpTextItems = { "[img=color_picker_white]", { "controls.smart-pipette" } },
                    Action = function(self)
                        return { Selecting = self.Item, Entity = self }
                    end,
                },
                {
                    UICode = "--- r",
                    IsRestricedTo = { Presentator = true, Remindor = true },
                    HelpTextTag = "ingteb-utility.create-reminder-task",
                    Action = function(self) return { RemindorTask = self.Item } end,
                },
            }
            return result:Concat(inherited)
        end,
    },

    HasSelectableRecipes = {
        cache = true,
        get = function(self) --
            return self.Prototype.type == "assembling-machine" and not self.Prototype.fixed_recipe
        end,
    },

    HasAutomaticRecipes = {
        cache = true,
        get = function(self)
            local prototype = self.Prototype
            return prototype.type == "furnace" or prototype.type == "rocket-silo"
                or prototype.fixed_recipe ~= nil
        end,
    },

    Required = {
        get = function(self)
            if self.Item then return self.Item.Required end
            if self.Prototype.type ~= "character" then dassert() end
            return RequiredThings:new()
        end,
    },

    IsEnabled = {
        get = function(self)
            if self.Item then return self.Item.IsEnabled end
            if self.Prototype.type == "character" then return true end
        end,
    },

    Modules = { get = function(self) return self.AllowedEffects:Select(function(effect) return effect.Items end):ConcatMany() end, },

    AllowedEffects = {
        get = function(self)
            return Dictionary:new(self.Prototype.allowed_effects or {})
                :Where(function(value) return value end)
                :ToArray(function(_, name) return self.Database:GetModuleEffect(name) end)
        end,
    },

    NotAllowedEffects = {
        get = function(self)
            return Dictionary:new(self.Prototype.allowed_effects or {})
                :Where(function(value) return not value end)
                :ToArray(function(_, name) return self.Database:GetModuleEffect(name) end)
        end,
    },
}

function Class:SortAll() end

function Class:GetSpeedFactor(category)
    if category.Domain == "rocket-launch" then
        return 1.0 / (self.Prototype.rocket_rising_delay + self.Prototype.launch_wait_time)
    elseif category.Domain == "burning" or category.Domain == "fluid-burning" then
        return self.MaximalEnergyConsumption
    elseif category.Domain == "boiling" then
        return 1
    elseif category.IsCraftingDomain then
        if self.Prototype.type == "character" then
            return 1
        else
            return self.Prototype.crafting_speed
        end
    elseif category.IsMiningDomain then
        return self.Prototype.mining_speed
    else
        dassert(false)
        return 1
    end
end

function Class:GetNumberOnSprite(category)
    return self:GetSpeedFactor(category) / category.SpeedFactor
end

function Class:new(name, prototype, database)

    local self = self:adopt(
        self.system.BaseClass:new(
            prototype or game.entity_prototypes[name], database
        )
    )

    if name then self.Name = name end
    if self.Name == "character" then self.TypeSubOrder = -1 end

    local prototype = self.Prototype

    dassert(self.Prototype.object_name == "LuaEntityPrototype")
    dassert(self.Prototype.type ~= "resource")

    self.HelpTextWhenUsedAsProduct = { "", self.RichTextName .. " ", self.Prototype.localised_name }

    return self

end

return Class
