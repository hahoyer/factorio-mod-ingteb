local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local ValueCache = require("core.ValueCache")
require("ingteb.Common")

function Technology(name, prototype, database)
    local self = Common(name, prototype, database)
    self.class_name = "Technology"
    self.Order = 3
    self.SpriteType = "technology"

    self.Time = self.Prototype.research_unit_energy

    self:addCachedProperty(
        "IsReady", function()
            return self.Prerequisites:All(
                function(technology) return technology.IsResearched end
            )
        end
    )

    self:addCachedProperty(
        "IsResearched", function()
            return global.Current.Player.force.technologies[self.Name].researched == true
        end
    )

    self.property.FunctionHelp = {
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

    self:addCachedProperty(
        "NumberOnSprite", function()
            if self.Prototype.level and self.Prototype.max_level > 1 then
                return self.Prototype.level
            end
        end
    )

    self.property.SpriteStyle = {
        get = function(self)
            if self.IsResearched then return end
            if self.IsReady then return Constants.GuiStyle.LightButton end
            return "red_slot_button"
        end,
    }

    function self:Refresh()
        self.cache.IsResearched.IsValid = false
        self.Enables:Select(function(technology) technology.cache.IsReady.IsValid = false end)
        self.EnabledRecipes:Select(function(recipes) recipes:Refresh() end)
    end

    self.Enables = Array:new()
    self.EnabledRecipes = Array:new()
    self.Effects = Array:new()

    self.property.Output = {
        get = function(self)
            return Array:new{self.Enables, self.EnabledRecipes, self.Effects}:ConcatMany()
        end,
    }

    self.IsDynamic = true

    function self:IsBefore(other)
        if self == other then return false end

        if self.class_name ~= other.class_name then return self.Order < other.Order end

        if self.IsResearched ~= other.IsResearched then return self.IsResearched end
        if self.IsReady ~= other.IsReady then return self.IsReady end

        return self.Prototype.order < other.Prototype.order
    end

    function self:Setup()
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

    return self
end

