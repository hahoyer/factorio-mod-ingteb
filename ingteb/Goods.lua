local Constants = require("Constants")

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
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
    AllUsedBy = {
        cache = true,
        get = function(self) return self.Database:GetUsedByRecipes(self.Prototype) end,
    },

    AllCreatedBy = {
        cache = true,
        get = function(self) return self.Database:GetCreatedByRecipes(self.Prototype) end,
    },

    PossibleUsedBy = {
        cache = true,
        get = function(self)
            return self.AllUsedBy--
                :Select(function(recipes) return recipes:Where(function(recipe) return recipe.IsPossible end) end)--
                :Where(function(recipes) return recipes:Any() and recipes[1].Category.Workers:Any() end)
            --
        end,
    },

    PossibleCreatedBy = {
        cache = true,
        get = function(self)
            return self.AllCreatedBy--
                :Select(function(recipes) return recipes:Where(function(recipe) return recipe.IsPossible end) end)--
                :Where(function(recipes) return recipes:Any() and recipes[1].Category.Workers:Any() end)
        end,
    },

    UsedBy = {
        get = function(self)
            local playerSettings = settings.get_player_settings(self.Player)
            if playerSettings["ingteb_show-impossible-recipes"].value then
                return self.AllUsedBy
            else
                return self.PossibleUsedBy
            end
        end,
    },

    CreatedBy = {
        get = function(self)
            local playerSettings = settings.get_player_settings(self.Player)
            if playerSettings["ingteb_show-impossible-recipes"].value then
                return self.AllCreatedBy
            else
                return self.PossibleCreatedBy
            end
        end,
    },

    AdditionalHelp = {
        get = function(self)
            local result = self.system.Inherited.Goods.AdditionalHelp.get(self) --
            if self.Prototype.fuel_value and self.Prototype.fuel_value > 0 then
                result:Append {
                    "",
                    { "description.fuel-value" },
                    " " .. FormatEnergy(self.Prototype.fuel_value),
                }
            end
            return result
        end,
    },

    SpecialFunctions = {
        get = function(self)
            local result = self.system.Inherited.Goods.SpecialFunctions.get(self)
            return result:Concat {
                {
                    UICode = "--- r",
                    HelpTextTag = "ingteb-utility.create-reminder-task",
                    Action = function(self, event)
                        return { RemindorTask = self, Count = event.element.number }
                    end,
                },
            }

        end,
    },

    AllRecipes = {
        cache = true,
        get = function(self)
            return self.CreatedBy:ToArray(function(recipes) return recipes end)--
                :ConcatMany()
        end,
    },

    Workers = {
        cache = true,
        get = function(self)
            local result = self.AllRecipes:Select(function(recipe) return recipe.Workers end)--
                :UnionMany()
            result:Sort(function(a, b) return a:IsBefore(b) end)
            return result
        end,
    },

    Required = {
        get = function(self)
            return self.AllRecipes:Select(function(recipe) return recipe.Required end)--
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
            local recipes = self.AllRecipes
            dassert(recipes)
            if recipes:Any(function(recipe) return recipe.IsEnabled end) then return true end
        end,
    },

}

function Class:SortAll()
end

function Class:CreateStack(amounts) return self.Database:CreateStackFromGoods(self, amounts) end

function Class:new(prototype, database)
    local self = self:adopt(self.system.BaseClass:new(prototype, database))

    return self

end

return Class
