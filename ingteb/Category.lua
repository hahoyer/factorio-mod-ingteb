local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("Category", Common)

local function GetPrototype(domain, subName)
    if domain == "crafting" then
        return game.recipe_category_prototypes[subName]
    elseif subName == "steel-axe" then
        return game.technology_prototypes["steel-axe"]
    elseif domain == "mining" or domain == "fluid-mining" then
        return game.resource_category_prototypes[subName]
    elseif domain == "boiling" or domain == "researching" then
        return game.entity_prototypes[subName]
    elseif domain == "rocket-launch" then
        return game.entity_prototypes["rocket-silo-rocket"]
    elseif domain == "burning" then
        return game.fuel_category_prototypes[subName]
    elseif domain == "fluid-burning" then
        dassert(subName == "fluid")
        return Helper.CreatePrototypeProxy { type = "fluid-burning", name = "fluid-burning" }
    else
        dassert()
    end
end

Class.system.Properties = {
    OriginalWorkers = {
        get = function(self)
            local workers = self.Database.BackLinks.WorkersForCategory[self.Name]
            if workers then
                return workers:ToArray(
                    function(worker) return self.Database:GetEntity(nil, worker) end
                )
            else
                return Array:new {}
            end
        end,
    },

    HelperHeaderText = {
        get = function(self) return Array:new { "ingteb-utility.workers-for-recipes" } end,
    },

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
            if self.Domain == "burning" or self.Domain == "fluid-burning" then
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
            local recipeList = self.Database.BackLinks.RecipesForCategory[self.Name] --
            local result = recipeList--
                :ToArray(
                    function(recipe)
                    if self.IsCraftingDomain then
                        if recipe.hidden and not self.HasAutomaticRecipes then return end
                        return self.Database:GetRecipe(nil, recipe)
                    elseif self.IsMiningDomain then
                        return self.Database:GetMiningRecipe(nil, recipe)
                    elseif self.Domain == "boiling" then
                        return self.Database:GetBoilingRecipe(nil, recipe)
                    elseif self.Domain == "burning" or self.Domain == "fluid-burning" then
                        return self.Database:GetBurningRecipe(nil, recipe)
                    elseif self.Domain == "rocket-launch" then
                        return self.Database:GetRocketLaunchRecipe(nil, recipe)
                    else
                        dassert()
                    end
                end
                )--
                :Where(function(recipe) return recipe end) --

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
            if self.Domain == "boiling" or self.Domain == "rocket-launch" or self.Domain == "burning" or self.Domain == "fluid-burning" then
                local workers = self.OriginalWorkers
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
            return self.Domain == "mining" or self.Domain == "fluid-mining" or self.Domain == "hand-mining"
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
    local result = self.OriginalWorkers
    result:Sort(function(a, b) return a:IsBefore(b) end)
    self.Workers = result
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
