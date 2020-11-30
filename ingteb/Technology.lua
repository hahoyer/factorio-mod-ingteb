local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local UI = require("core.UI")

local Technology = Common:class("Technology")

function Technology:new(name, prototype, database)

    local self = Common:new(prototype or game.technology_prototypes[name], database)
    self.object_name = Technology.object_name

    assert(self.Prototype.object_name == "LuaTechnologyPrototype")

    self.TypeOrder = 3
    self.SpriteType = "technology"
    self.Technologies = Array:new()
    self.IsDynamic = true
    self.Time = self.Prototype.research_unit_energy

    self:properties{
        Input = {
            get = function() --
                return Array:new(self.Prototype.research_unit_ingredients) --
                :Select(
                    function(tag)
                        tag.amount = tag.amount * self.Prototype.research_unit_count
                        local result = database:GetStackOfGoods(tag)
                        result.Item.UsedBy:AppendForKey(" researching", self)
                        return result
                    end
                ) --
                :Concat(self.Prerequisites)
            end,
        },

        Output = {
            get = function() --
                return Array:new{self.Enables, self.EnabledRecipes, self.Effects}:ConcatMany()
            end,
        },

        NumberOnSprite = {
            get = function() --
                if self.Prototype.level and self.Prototype.max_level > 1 then
                    return self.Prototype.level
                end
            end,
        },

        FunctionHelp = {
            get = function() --
                if not self.IsResearched and self.IsReady then
                    return {
                        "ingteb_utility.research",
                        {"control-keys.alt"},
                        {"control-keys.control"},
                        {"control-keys.shift"},
                        {"control-keys.mouse-button-1-alt-1"},
                        {"control-keys.mouse-button-2-alt-1"},
                    }
                end
            end,
        },

        SpriteStyle = {
            get = function()
                if self.IsResearched then return end
                return self.IsReady
            end,
        },
        IsResearched = {
            get = function()
                return global.Current.Player.force.technologies[self.Name].researched == true
            end,
        },
        IsReady = {
            cache = true,
            get = function()
                return self.Prerequisites:All(
                    function(technology) return technology.IsResearched end
                )
            end,
        },

        Prerequisites = {
            get = function()
                return Dictionary:new(self.Prototype.prerequisites) --
                :ToArray() --
                :Select(
                    function(technology)
                        return self.Database:GetTechnology(nil, technology)
                    end
                )
            end,
        },

        Enables = {
            cache = true,
            get = function()
                return self.Database.EnabledTechnologiesForTechnology[self.Name] --
                :Select(
                    function(technology)
                        return self.Database:GetTechnology(nil, technology)
                    end
                )
            end,
        },

        EnabledRecipes = {
            cache = true,
            get = function()
                return Dictionary:new(self.Prototype.effects) --
                :Where(function(effect) return effect.type == "unlock-recipe" end) --
                :Select(
                    function(effect)
                        return self.Database:GetRecipe(effect.recipe)
                    end
                )
            end,
        },

        Effects = {
            cache = true,
            get = function()
                return Dictionary:new(self.Prototype.effects) --
                :Where(function(effect) return effect.type ~= "unlock-recipe" end) --
                :Select(function(effect) return self.Database:GetBonus(effect) end)
            end,
        },
    }

    function self:Refresh()
        self.Enables:Select(function(technology) technology.cache.IsReady.IsValid = false end)
        self.EnabledRecipes:Select(function(recipe) recipe:Refresh() end)
    end

    function self:IsBefore(other)
        if self == other then return false end
        if self.TypeOrder ~= other.TypeOrder then return self.TypeOrder < other.TypeOrder end
        if self.IsResearched ~= other.IsResearched then return self.IsResearched end
        if self.IsReady ~= other.IsReady then return self.IsReady end
        return self.Prototype.order < other.Prototype.order
    end

    function self:SortAll() end

    function self:GetResearchOrder(event)
        if UI.IsMouseCode(event, "-C- l") --
        and self.IsReady --
        then return {Technology = self.Prototype} end
    end
    

    return self

end

return Technology
