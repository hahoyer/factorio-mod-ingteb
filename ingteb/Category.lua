local translation = require("__flib__.translation")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("Category", Common)

local function GetPrototype(domain, category)
    if domain == "crafting" then
        return game.recipe_category_prototypes[category]
    elseif category == "steel-axe" then
        return game.technology_prototypes["steel-axe"]
    elseif domain == "mining" or domain == "fluid-mining" then
        return game.resource_category_prototypes[category]
    elseif domain == "boiling" then
        return game.entity_prototypes[category]
    else
        dassert()
    end
end

Class.system.Properties = {
    OriginalWorkers = {
        get = function(self)
            local w = self.Database.WorkersForCategory[self.Name]
            return self.Database.WorkersForCategory[self.Name] --
            :Select(function(worker) return self.Database:GetEntity(nil, worker) end)
        end,
    },

    HelperHeaderText = {
        get = function(self) return Array:new{"ingteb-utility.workers-for-recipes"} end,
    },

    AdditionalHelp = {
        get = function(self)
            local result = Array:new{}
            if self.Name == "crafting.crafting" then return result end

            local name = self.LocalisedName
            if self.Domain ~= "crafting" then
                name = {
                    "",
                    "[font=default-small]",
                    {"ingteb-recipe-category-domain-name." .. self.Domain},
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
            return Array:new{
                -- {
                --     UICode = "--- l",
                --     HelpText = "ingteb-utility.category-settings",
                --     Action = function(self) return {Settings = self} end,
                -- },
            }
        end,
    },

    RecipeList = {
        cache = true,
        get = function(self)
            local recipeList = self.Database.RecipesForCategory[self.Name] or Array:new{} --
            local result = recipeList --
            :Select(
                function(recipeName)
                    if self.Domain == "crafting" then
                        return self.Database:GetRecipe(recipeName)
                    elseif self.Domain == "mining" or self.Domain == "fluid-mining" or self.Domain
                        == "hand-mining" then
                        return self.Database:GetMiningRecipe(recipeName)
                    elseif self.Domain == "boiling" then
                        return self.Database:GetBoilingRecipe(recipeName, self.Prototype)
                    else
                        dassert()
                    end
                end
            ) --
            :Where(function(recipe) return recipe end) --
            return result
        end,
    },
}

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

    local _, _, domain, category = name:find("^(.-)%.(.*)$")

    local self = self:adopt(
        self.system.BaseClass:new(
            prototype or GetPrototype(domain, category), database
        )
    )
    self.Domain = domain
    self.SubName = category
    self.Name = self.Domain .. "." .. self.SubName
    return self

end

return Class

