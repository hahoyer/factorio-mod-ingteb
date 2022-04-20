local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require "ingteb.RecipeCommon"
local class = require("core.class")

local Class = class:new("FuelRecipe", Common)

local function GetCategoryAndRegister(self, domain, category)
    local result = self.Database:GetCategory(domain .. "." .. category)
    return result
end

Class.system.Properties = {}

function Class:new(name, prototype, database)
    local self = self:adopt(self.system.BaseClass:new(prototype, database))
    self.Name = name
    self.Time = 1
    self.Category = GetCategoryAndRegister(self, "fuelProcessing", name)
    self.TypeStringForLocalisation = "ingteb-utility.title-fuelProcessing-recipe"

    local input = self.Database:GetStackOfGoods { type = prototype.type, amount = 1, name = name }
    input.Source = { Recipe = self, ProductIndex = 1 }
    input.Goods.UsedBy:AppendForKey(self.Category.Name, self)
    self.Input = Array:new { input }

    local output = self.Database:GetStackOfGoods { type = "fluid", amount = 60, name = "steam" }
    output.Goods.CreatedBy:AppendForKey(self.Category.Name, self)
    output.Source = { Recipe = self, IngredientIndex = 1 }
    self.Output = Array:new { output }

    return self
end

return Class
