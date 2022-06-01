local Constants = require("Constants")
local Configurations = require("Configurations").Database
local Number = require "core.Number"
local Helper = require("ingteb.Helper")
local RequiredThings = require("ingteb.RequiredThings")
local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("Entity", Common)

Class.system.Properties = {
    SpriteType = { get = function(self) return "entity" end },
    GameType = { get = function(self) return "entity" end },
    TypeStringForLocalisation = { get = function(self)
        local type = self.IsResource and "resource" or "entity"
        return "ingteb-type-name." .. type
    end },
    UsedBy = {
        --cache = true,
        get = function(self) return self.Database:GetUsedByRecipes(self.Prototype) end,
    },

    CreatedBy = {
        --cache = true,
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

    Item = {
        cache = true,
        get = function(self)
            local place = self.Prototype.items_to_place_this
            if not place or #place == 0 then return end
            -- todo: present multiple items_to_place_this
            return self.Database:GetItem(place[1].name)
        end,
    },

    IsResource = { get = function(self) return Configurations.ResourceTypes[self.Prototype.type] end },
    HasFluidHandling = { get = function(self) return #self.Prototype.fluidbox_prototypes > 0 end },

    HasEnergyConsumption = { get = function(self)
        local prototype = self.Prototype
        return prototype.burner_prototype and prototype.burner_prototype.fuel_inventory_size > 0
            and prototype.max_energy_usage and prototype.max_energy_usage > 0
    end },

    RequiresFluidHandling = { get = function(self)
        local prototype = self.Prototype
        return prototype.mineable_properties.required_fluid --
            or Array:new(prototype.mineable_properties.products)--
            :Any(function(product) return product.type == "fluid" end) --

    end },

    RequiresNoFluidHandling = { get = function(self) return not self.RequiresFluidHandling end },

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
            if not usage or usage == 0 then return end

            local result = usage * 60
            if prototype.burner_prototype and prototype.burner_prototype.effectivity and prototype.burner_prototype.effectivity ~= 1 then
                result = result / prototype.burner_prototype.effectivity
            end
            dassert(result ~= 0)
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

    IsValidBurner = {
        get = function(self)
            local prototype = self.Prototype
            return prototype.burner_prototype and prototype.burner_prototype.fuel_inventory_size and prototype.burner_prototype.fuel_inventory_size > 0
        end,
    },

    FuelCategories = {
        cache = true,
        get = function(self)
            local prototype = self.Prototype
            local usage = prototype.max_energy_usage
            if not usage or usage == 0 then return end

            return self.Categories--
                :Where(
                    function(category)
                        return category.Domain == "Burning" or category.Domain == "fluid_burning"
                    end
                )--
                :ToArray(
                    function(category)
                        local name = category.Domain == "fluid_burning" and "fluid" or category.SubName
                        return self.Database:GetFuelCategory(name)
                    end
                )
        end,
    },

    UsefulLinks = { get = function(self) return Array:new { self.FuelCategories, self.Modules, } end, },

    Categories = {
        get = function(self)
            local prototype = self.Prototype
            if prototype.is_building or prototype.type == "character" then
                local xreturn = Dictionary
                    :new(Configurations.RecipeDomains)
                    :ToArray(function(_, domainName)
                        return Array:new(self:GetCategoryNames(domainName))
                            :Select(function(categoryName)
                                return self.Database:GetCategory(domainName .. "." .. categoryName)
                            end)
                    end)
                    :ConcatMany()
                    :ToDictionary(function(category) return { Key = category.Name, Value = category } end)
                return xreturn
            else
                return Dictionary:new()
            end
        end
    },

    AllRecipes = {
        cache = true,
        get = function(self)
            local xreturn = self.Categories--
                :Select(function(category) return category.AllRecipes end)--
                :Where(function(recipes) return recipes:Any() end) --
            return xreturn
        end,
    },
    PossibleRecipes = {
        cache = true,
        get = function(self)
            local xreturn = self.Categories--
                :Select(function(category) return category.PossibleRecipes end)--
                :Where(function(recipes) return recipes:Any() and recipes[1].Category.Workers:Any() end)
            return xreturn
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

function Class:CreateStack(amounts)
    dassert(self.IsResource)
    return self.Database:CreateStackFromGoods(self, amounts)
end

function Class:GetCategoryNames(domainName)
    local setup = Configurations.RecipeDomains[domainName]
    return Dictionary:new(global.Game[setup.GameType])
        :Where(function(category)
            local setup = setup.Worker
            local categoryData = category[Helper.GetNestedPath(setup.BackLinkPath)]
            if not categoryData then return Array:new() end
            return Dictionary
                :new(categoryData.entity)
                :Any(function(entity)
                    return entity.Proxy.Name == self.Name
                        and (not setup.Condition or self[setup.Condition])
                end)
        end)
        :ToArray(function(_, name) return name end)
end

function Class:GetSpeedFactor(category)
    if category.Domain == "rocket_launch" then
        return 1.0 / (self.Prototype.rocket_rising_delay + self.Prototype.launch_wait_time)
    elseif category.Domain == "Burning" or category.Domain == "fluid_burning" then
        return self.MaximalEnergyConsumption
    elseif category.Domain == "Boiling" then
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
    dassert(self.Prototype.type ~= "resource" or
        Configurations.ResourceTypes[self.Prototype.type])

    self.HelpTextWhenUsedAsProduct = { "", self.RichTextName .. " ", self.Prototype.localised_name }

    return self

end

return Class
