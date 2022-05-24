local Constants = require("Constants")
local Configurations = require("Configurations").Database
local Helper = require("ingteb.Helper")

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("Category", Common)

local function GetPrototype(domain, subName)
    if domain == "crafting" then
        return game.recipe_category_prototypes[subName]
    elseif subName == "steel-axe" then
        return game.technology_prototypes["steel-axe"]
    elseif domain == "mining" or domain == "fluid_mining" then
        return game.resource_category_prototypes[subName]
    elseif domain == "boiling" or domain == "researching" then
        return game.entity_prototypes[subName]
    elseif domain == "rocket_launch" then
        return game.entity_prototypes["rocket-silo-rocket"]
    elseif domain == "burning" then
        return game.fuel_category_prototypes[subName]
    elseif domain == "fluid_burning" then
        dassert(subName == "fluid")
        return Helper.CreatePrototypeProxy { type = "fluid_burning", name = "fluid_burning" }
    else
        dassert()
    end
end

Class.system.Properties = {
    Configuration = { get = function(self) return Configurations.RecipeDomains[self.Domain] end },
    BackLinkType = { get = function(self) return self.Configuration.BackLinkType end },
    BackLinkName = { get = function(self) return self.SubName end },
    Workers = {
        cache = true,
        get = function(self)
            local result = self.AllWorkers
            if self.Configuration.WorkerCondition then
                result = result:Where(function(worker) return worker[self.Configuration.WorkerCondition] end)
            end
            result:Sort(function(a, b) return a:IsBefore(b) end)
            return result
        end,
    },
    AllWorkers = { get = function(self)
        local result = self:GetBackLinkArray(self.Configuration.Workers, "entity")
        return result
    end,
    },
    HelperHeaderText = { get = function(self) return Array:new { "ingteb-utility.workers-for-recipes" } end, },
    AdditionalHelp = {
        get = function(self)
            local result = Array:new {}
            if self.Name == "crafting.crafting" then return result end

            local name = self.LocalisedName
            if self.Domain ~= "crafting" then
                name = {
                    "",
                    "[font=default-small]",
                    { "ingteb-recipe-category-domain-name." .. self.Domain },
                    ": ",
                    name,
                    "[/font]",
                }
            end
            result:Append(name)
            return result
        end,
    },

    SpecialFunctions = {
        get = function(self) --
            return Array:new {
                -- {
                --     UICode = "--- l",
                --     HelpTextTag = "ingteb-utility.category-settings",
                --     Action = function(self) return {Settings = self} end,
                -- },
            }
        end,
    },

    HasAutomaticRecipes = {
        cache = true,
        get = function(self)
            return self.Workers:Any(function(worker) return worker.HasAutomaticRecipes end)
        end,
    },

    HasSelectableRecipes = {
        cache = true,
        get = function(self) --
            dassert(self.IsSealed)
            return self.IsCraftingDomain
                and self.Workers:Any(function(worker) return worker.HasSelectableRecipes end)
        end,
    },

    LineSprite = {
        cache = true,
        get = function(self)
            if self.Domain == "burning" or self.Domain == "fluid_burning" then
                return "utility/slot_icon_fuel_black"
            else
                return "utility/change_recipe"
            end
        end,
    },

    PossibleRecipes = {
        cache = true,
        get = function(self)
            return self.AllRecipes:Where(function(recipe) return recipe.IsPossible end)
        end,
    },

    AllRecipes = {
        cache = true,
        get = function(self)

            local setup = self.Configuration
            local recipePrimaryList = self:GetBackLinkArray(setup.Recipes, setup.RecipePrimary or "recipe")
            if setup.RecipeCondition then
                recipePrimaryList = recipePrimaryList
                    :Where(function(recipePrimary) return recipePrimary[setup.RecipeCondition] end)
            end

            local result = recipePrimaryList
                :Select(
                    function(recipePrimary)
                        return self.Database:GetRecipeFromPrimary(self.Domain, recipePrimary)
                    end)
            return result
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

    SpeedFactor = {
        cache = true,
        get = function(self) --
            dassert(self.IsSealed)
            if self.Domain == "boiling" or self.Domain == "rocket_launch" or self.Domain == "burning" or self.Domain == "fluid_burning" then
                local workers = self.Workers
                if workers:Any() then
                    return workers:Select(function(worker) return worker:GetSpeedFactor(self) end):Minimum()
                else
                    return 1
                end
            elseif self.IsCraftingDomain or self.IsMiningDomain then
                return 1
            else
                dassert(false, "domain = " .. self.Domain)
            end
        end,
    },

    IsMiningDomain = {
        get = function(self) --
            return self.Domain == "mining" or self.Domain == "fluid_mining" or self.Domain == "hand_mining"
        end,
    },

    IsCraftingDomain = { get = function(self) return self.Domain == "crafting" end, },
}

function Class:GetReactorBurningTime(fuelValue) return fuelValue / self.ReactorEnergyUsage / 60 end

function Class:SealUp()
    self.class.system.BaseClass.SealUp(self)
    return self
end

function Class:SortAll()
end

function Class:AssertValid() end

function Class:new(name, prototype, database)
    dassert(name)
    dassert(not prototype or not prototype.object_name)

    local _, _, domain, subName = name:find("^(.-)%.(.*)$")

    local self = self:adopt(
        self.system.BaseClass:new(
            prototype or GetPrototype(domain, subName), database
        )
    )

    self.Domain = domain
    self.SubName = subName
    self.Name = self.Domain .. "." .. self.SubName
    return self

end

return Class
