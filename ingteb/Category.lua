local Constants = require("Constants")
local Configurations = require("Configurations").Database
local Helper = require("ingteb.Helper")

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("Category", Common)

Class.system.Properties = {
    Configuration = { get = function(self) return Configurations.RecipeDomains[self.Domain] end },
    GameType = { get = function(self) return self.Configuration.GameType end },
    BackLinkName = { get = function(self) return self.SubName end },
    Workers = {
        cache = true,
        get = function(self)
            local result = self.AllWorkers
            if self.Configuration.Worker.Condition then
                result = result:Where(function(worker) return worker[self.Configuration.Worker.Condition] end)
            end
            result:Sort(function(a, b) return a:IsBefore(b) end)
            return result
        end,
    },
    AllWorkers = { get = function(self)
        local result = self:GetBackLinkArray(self.Configuration.Worker.BackLinkPath, "entity")
        return result
    end,
    },
    HelperHeaderText = { get = function(self) return Array:new { "ingteb-utility.workers-for-recipes" } end, },
    AdditionalHelp = {
        get = function(self)
            local result = Array:new {}
            if self.Name == "Crafting.crafting" then return result end

            local name = self.LocalisedName
            if self.Domain ~= "Crafting" then
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
            if self.Domain == "Burning" or self.Domain == "fluid_burning" then
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
            return self:GetBackLinkArray("category", self.Configuration.Recipe.GameType)
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
            if self.Domain == "Boiling" or self.Domain == "RocketLaunch" or self.Domain == "Burning" or self.Domain == "FluidBurning" then
                local workers = self.Workers
                if workers:Any() then
                    return workers:Select(function(worker) return worker:GetSpeedFactor(self) end):Minimum()
                else
                    return 1
                end
            elseif self.IsCraftingDomain or self.IsMiningDomain then
                return 1
            else
                dassert(false, "unknown domain: " .. self.Domain)
            end
        end,
    },

    IsMiningDomain = {
        get = function(self) --
            return self.Domain == "Mining" or self.Domain == "FluidMining" or self.Domain == "HandMining"
        end,
    },

    IsCraftingDomain = { get = function(self) return self.Domain == "Crafting" end, },
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
    dassert(not prototype)
    local _, _, domain, subName = name:find("^(.-)%.(.*)$")
    local configuration = Configurations.RecipeDomains[domain]
    local proxy = database.Game[configuration.GameType][subName]
    local prototype = proxy.Prototype or game[proxy.Type .. "_prototypes"][proxy.Name]
    local self = self:adopt(self.system.BaseClass:new(prototype, database))

    self.Domain = domain
    self.SubName = subName
    self.Name = self.Domain .. "." .. self.SubName
    return self

end

return Class
