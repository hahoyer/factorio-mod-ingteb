local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")

local Category = Common:class("Category")

local function GetPrototype(domain, category)
    if domain == "crafting" then
        return game.recipe_category_prototypes[category]
    elseif category == "steel-axe" then
        return game.technology_prototypes["steel-axe"]
    elseif domain == "mining" or domain == "fluid-mining" then
        return game.resource_category_prototypes[category]
    elseif domain == "boiling" then
        return game.fluid_prototypes[category]
    else
        assert(release)
    end
end

function Category:new(name, prototype, database)
    assert(release or name)

    local _, _, domain, category = name:find("^(.+)%.(.*)$")

    local p = GetPrototype(domain, category)
    if not p then __DebugAdapter.breakpoint() end
    local self = Common:new(prototype or GetPrototype(domain, category), database)
    self.object_name = Category.object_name
    self.Domain = domain
    self.SubName = self.Prototype.name
    self.Name = self.Domain .. "." .. self.SubName

    self:properties{
        Workers = {
            cache = true,
            get = function()
                local result = self.Database.WorkersForCategory[self.Name] --
                :Select(function(worker) return self.Database:GetEntity(nil, worker) end)

                if self.Domain == "mining" or self.Domain == "hand-mining" then
                    result:Append(
                        self.Database:GetEntity("(hand-miner)", game.entity_prototypes["character"])
                    )
                end

                return result
            end,
        },

        RecipeList = {
            cache = true,
            get = function()
                local recipeList = self.Database.RecipesForCategory[self.Name] or Array:new{} --
                local result = recipeList --
                :Select(
                    function(recipeName)
                        if self.Domain == "crafting" then
                            return self.Database:GetRecipe(recipeName)
                        else
                            return self.Database:GetImplicitRecipeForDomain(self.Domain, recipeName)
                        end
                    end
                ) --
                :Where(function(recipe) return recipe end) --
                return result
            end,
        },
    }

    self.cache.Workers.IsValid = true

    function self:SortAll() end

    return self

end

return Category

