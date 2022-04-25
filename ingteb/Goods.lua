local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local function FormatEnergy(value)
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

local Class = class:new("Goods", Common)

Class.system.Properties = {
    OriginalRecipeList = {
        get = function(self) return self.Entity and self.Entity.RecipeList or Dictionary:new{} end,
    },

    OriginalUsedBy = {
        cache = true,
        get = function(self) return self.Database:GetUsedByRecipes(self.Prototype) end,
    },

    OriginalCreatedBy = {
        cache = true,
        get = function(self) return self.Database:GetCreatedByRecipes(self.Prototype) end,
    },

    AdditionalHelp = {
        get = function(self)
            local result = self.inherited.Goods.AdditionalHelp.get(self) --
            if self.Prototype.fuel_value and self.Prototype.fuel_value > 0 then
                result:Append{
                    "",
                    {"description.fuel-value"},
                    " " .. FormatEnergy(self.Prototype.fuel_value),
                }
            end
            return result
        end,
    },

    SpecialFunctions = {
        get = function(self)
            local result = self.inherited.Goods.SpecialFunctions.get(self)
            return result:Concat{
                {
                    UICode = "--- r",
                    HelpText = "ingteb-utility.create-reminder-task",
                    Action = function(self, event)
                        return {RemindorTask = self, Count = event.element.number}
                    end,
                },
            }

        end,
    },

    Recipes = {
        cache = true,
        get = function(self)
            return self.CreatedBy:ToArray(function(recipes) return recipes end) --
            :ConcatMany()
        end,
    },

    Workers = {
        cache = true,
        get = function(self)
            local result = self.Recipes:Select(function(recipe) return recipe.Workers end) --
            :UnionMany()
            result:Sort(function(a, b) return a:IsBefore(b) end)
            return result
        end,
    },

    Required = {
        get = function(self)
            return self.Recipes:Select(function(recipe) return recipe.Required end) --
            :Aggregate(
                function(c, n)
                    if not c then return n end
                    dassert()
                end
            )
        end,
    },

    IsEnabled = {
        get = function(self)
            local recipes = self.Recipes
            dassert(recipes)
            if recipes:Any(function(recipe) return recipe.IsResearched end) then return true end
        end,
    },

}

local function Sort(target)
    local targetArray = target:ToArray(function(value, key) return {Value = value, Key = key} end)
    targetArray:Sort(
        function(a, b)
            if a == b then return false end
            local aOrder = a.Value:Select(function(recipe) return recipe.Order end):Sum()
            local bOrder = b.Value:Select(function(recipe) return recipe.Order end):Sum()
            if aOrder ~= bOrder then return aOrder > bOrder end

            local aSubOrder = a.Value:Select(function(recipe) return recipe.SubOrder end):Sum()
            local bSubOrder = b.Value:Select(function(recipe) return recipe.SubOrder end):Sum()
            return aSubOrder > bSubOrder

        end
    )

    return targetArray:ToDictionary(
        function(value)
            value.Value:Sort(
                function(a, b) --
                    return a:IsBefore(b)
                end
            )
            return value
        end
    )

end

function Class:SortAll()
    if not self.RecipeList then self.RecipeList = self.OriginalRecipeList end
    if not self.CreatedBy then self.CreatedBy = self.OriginalCreatedBy end
    if not self.UsedBy then self.UsedBy = self.OriginalUsedBy end

    self.RecipeList = Sort(self.RecipeList)
    self.CreatedBy = Sort(self.CreatedBy)
    self.UsedBy = Sort(self.UsedBy)
end

function Class:CreateStack(amounts) return self.Database:CreateStackFromGoods(self, amounts) end

function Class:new(prototype, database)
    local self = self:adopt(self.system.BaseClass:new(prototype, database))

    return self

end

return Class
