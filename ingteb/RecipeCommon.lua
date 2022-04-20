local Constants = require("Constants")
local Table = require("core.Table")
local RequiredThings = require("ingteb.RequiredThings")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("RecipeCommon", Common)

Class.system.Properties = {
    Workers = {
        get = function(self)
            local result = self.Category.Workers
            result:Sort(function(a, b) return a:IsBefore(b) end)
            return result
        end,
    },
    OrderValue = {
        cache = "player",
        get = function(self)
            return self.TypeOrder --
                .. " R R " --
                .. self.Prototype.group.order --
                .. " " .. self.Prototype.subgroup.order --
                .. " " .. self.Prototype.order
        end,
    },
    Category = {
        cache = true,
        get = function(self)
            return self.Database:GetCategory(self.Prototype.type .. "." .. self.Prototype.category)
        end
    },

    IsHidden = { get = function(self) return self.Prototype.hidden end },
    Required = { get = function(self) return RequiredThings:new(nil, self.Input) end },
    Time = { get = function(self) return self.Prototype.energy or self.Category.Time end },
    SpriteType = { get = function(self) return self.Prototype.sprite_type end },
    TypeStringForLocalisation = { get = function(self) return "ingteb-utility.title-" .. self.Prototype.type .. "-recipe" end },

    Output = {
        cache = true,
        get = function(self)
            return Array:new(self.Prototype.products)--
                :Select(
                    function(product, index)
                        local result = self.Database:GetStackOfGoods(product)
                        dassert(result)
                        result.Source = { Recipe = self, ProductIndex = index }
                        return result
                    end
                )--
                :Where(function(value) return value end) --
        end,
    },
    Input = {
        cache = true,
        get = function(self)
            return Array:new(self.Prototype.ingredients)--
                :Select(
                    function(ingredient, index)
                        if ingredient.type == "entity" then
                            return self.Database:GetEntity(ingredient.name)
                        else
                            local result = self.Database:GetStackOfGoods(ingredient)
                            dassert(result)
                            result.Source = { Recipe = self, IngredientIndex = index }
                            return result
                        end
                    end
                )--
                :Where(
                    function(value)
                        return not (value.flags and value.flags.hidden)
                    end
                ) --
        end,
    },


}

function Class:new(name, prototype, database)
    dassert(not name)
    dassert(prototype)
    dassert(database)
    
    local self = self:adopt(self.system.BaseClass:new(prototype, database))
    self.Name = prototype.name

    self.IsRecipe = true

    function self:IsBefore(other)
        if self == other then return false end
        return self.OrderValue < other.OrderValue
    end

    function self:SortAll() end

    return self
end

return Class
