local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
require("ingteb.Common")
local Common = require("ingteb.Common")

function OldTechnology(name, prototype, database)
    local result = Common(name, prototype, database)
    result.object_name = "Technology"
    result.Order = 3
    result.SpriteType = "technology"

    result.Time = result.Prototype.research_unit_energy

    result:addCachedProperty(
        "IsReady", function()
            return result.Prerequisites:All(
                function(technology) return technology.IsResearched end
            )
        end
    )

    result:addCachedProperty(
        "IsResearched", function()
            return global.Current.Player.force.technologies[result.Name].researched == true
        end
    )

    result.property.FunctionHelp = {
        get = function(self) --
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
    }

    result:addCachedProperty(
        "NumberOnSprite", function()
            if result.Prototype.level and result.Prototype.max_level > 1 then
                return result.Prototype.level
            end
        end
    )

    result.property.SpriteStyle = {
        get = function(self)
            if self.IsResearched then return end
            if self.IsReady then return "ingteb-light-button" end
            return "red_slot_button"
        end,
    }

    function result:Refresh()
        self.cache.IsResearched.IsValid = false
        self.Enables:Select(function(technology) technology.cache.IsReady.IsValid = false end)
        self.EnabledRecipes:Select(function(recipes) recipes:Refresh() end)
    end

    result.Enables = Array:new()
    result.EnabledRecipes = Array:new()
    result.Effects = Array:new()

    result.property.Output = {
        get = function(self)
            return Array:new{self.Enables, self.EnabledRecipes, self.Effects}:ConcatMany()
        end,
    }

    result.IsDynamic = true

    function result:IsBefore(other)
        if self == other then return false end

        if self.object_name ~= other.object_name then return self.Order < other.Order end

        if self.IsResearched ~= other.IsResearched then return self.IsResearched end
        if self.IsReady ~= other.IsReady then return self.IsReady end

        return self.Prototype.order < other.Prototype.order
    end

    function result:Setup()
        self.Prerequisites = Dictionary:new(self.Prototype.prerequisites) --
        :ToArray() --
        :Select(
            function(technology)
                local result = self.Database.Technologies[technology.name]
                result.Enables:Append(self)
                return result
            end
        )

        self.Input = Array:new(self.Prototype.research_unit_ingredients) --
        :Select(
            function(tag)
                tag.amount = tag.amount * self.Prototype.research_unit_count
                local result = database:GetItemSet(tag)
                result.Item.UsedBy:AppendForKey(" researching", self)
                return result
            end
        ) --
        :Concat(self.Prerequisites)

        Array:new(self.Prototype.effects) --
        :Select(
            function(effect)
                if effect.type == "unlock-recipe" then
                    local result = database.Recipes[effect.recipe]
                    result.Technologies:Append(self)
                    self.EnabledRecipes:Append(result)
                else
                    self.Effects:Append(database:AddBonus(effect, self))
                end
            end
        ) --

    end

    return result
end

local Technology = Common:class("Technology")

function Technology:new(name, prototype, database)

    local self = Common:new(prototype or game.technology_prototypes[name], database)
    self.object_name = Technology.object_name
    self.TypeOrder = 3
    self.SpriteType = "technology"
    self.Technologies = Array:new()

    assert(self.Prototype.object_name == "LuaTechnologyPrototype")
    self:properties{}
    return self

end

return Technology
