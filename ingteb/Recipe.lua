local Constants = require("Constants")
local Table = require("core.Table")
local RequiredThings = require "ingteb.RequiredThings"
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local UI = require("core.UI")
local class = require("core.class")

local Recipe = class:new("Recipe", Common)

Recipe.property = {

    Technologies = {
        cache = true,
        get = function(self)
            local xreturn = (self.Database.TechnologiesForRecipe[self.Name] or Array:new{}) --
            :Select(
                function(prototype)
                    return self.Database:GetTechnology(nil, prototype)
                end
            )
            return xreturn
        end,
    },

    IsResearched = {
        get = function(self)
            return --
            not self.Technologies:Any() --
                or self.Technologies:Any(
                    function(technology) return technology.IsResearched end
                )
        end,
    },

    NotResearchedTechnologiesForRecipe = {
        get = function(self)
            local result = self.Technologies --
            :Select(function(technology) return technology.NotResearchedPrerequisites end) --
            :GetShortest()
            return result
        end,
    },

    Technology = {
        get = function(self)
            if self.Technologies:Count() <= 1 then return self.Technologies:Top() end

            local researched = self.Technologies --
            :Where(function(technology) return technology.IsResearched end)
            if researched:Count() > 0 then return researched:Top() end

            local ready = self.Technologies --
            :Where(function(technology) return technology.IsReady end)
            if ready:Count() > 0 then return researched:Top() end

            return self.Technologies:Top()
        end,
    },

    OrderValue = {
        cache = true,
        get = function(self)
            return --
            self.TypeOrder .. " " --
            .. (self.IsResearched and "R" or "r") .. " "
                .. (not self.IsResearched and self.Technology.IsReady and "R" or "r") .. " "
                .. self.Prototype.group.order .. " " .. self.Prototype.subgroup.order .. " "
                .. self.Prototype.order
        end,
    },

    NumberOnSprite = {
        get = function(self)
            if not self.HandCrafter then return end
            local result = UI.Player.get_craftable_count(self.Prototype.name)
            if result > 0 then return result end
        end,
    },

    Category = {
        cache = true,
        get = function(self)
            return self.Database:GetCategory("crafting." .. self.Prototype.category)
        end,
    },

    HandCrafter = {
        get = function(self)
            return self.Category.Workers:Where(
                function(worker) return worker.Prototype.name == "character" end
            ):Top()
        end,
    },

    Workers = {
        get = function(self)
            local result = self.Category.Workers
            result:Sort(function(a, b) return a:IsBefore(b) end)
            return result
        end,
    },

    SpriteStyle = {
        get = function(self)
            if not self.IsResearched then return false end
            if self.NumberOnSprite then return true end
        end,
    },

    Output = {
        cache = true,
        get = function(self)

            return Array:new(self.Prototype.products) --
            :Select(
                function(product, index)
                    local result = self.Database:GetStackOfGoods(product)
                    if result then
                        result.Source = {Recipe = self, ProductIndex = index}
                    else
                        self.IsHidden = true
                    end
                    return result
                end
            ) --
            :Where(function(value) return value end) --

        end,
    },
    Input = {
        cache = true,
        get = function(self)
            return Array:new(self.Prototype.ingredients) --
            :Select(
                function(ingredient, index)
                    local result = self.Database:GetStackOfGoods(ingredient)
                    if result then
                        result.Source = {Recipe = self, IngredientIndex = index}
                    else
                        self.IsHidden = true
                    end
                    return result
                end
            ) --
            :Where(function(value) return not (value.flags and value.flags.hidden) end) --

        end,
    },

    SpecialFunctions = {
        get = function(self) --
            local result = self.inherited.Recipe.SpecialFunctions.get(self)
            return result:Concat{
                {
                    UICode = "A-- l",
                    HelpText = "controls.craft",
                    IsAvailable = function(self)
                        return self.HandCrafter and self.NumberOnSprite
                    end,
                    Action = function(self, event)
                        return {HandCrafting = {count = 1, recipe = self.Name}}
                    end,
                },
                {
                    UICode = "A-- r",
                    HelpText = "controls.craft-5",
                    IsAvailable = function(self)
                        return self.HandCrafter and self.NumberOnSprite
                    end,
                    Action = function(self)
                        return {HandCrafting = {count = 5, recipe = self.Name}}
                    end,
                },
                {
                    UICode = "--S l",
                    HelpText = "controls.craft-all",
                    IsAvailable = function(self)
                        return self.HandCrafter and self.NumberOnSprite
                    end,

                    Action = function(self, event)
                        local amount = game.players[event.player_index].get_craftable_count(
                            self.Prototype.name
                        )
                        return {HandCrafting = {count = amount, recipe = self.Name}}
                    end,
                },
                {
                    UICode = "-C- l",
                    HelpText = "gui-technology-preview.start-research",
                    IsAvailable = function(self)
                        return self.Technology and self.Technology.IsReady
                    end,
                    Action = function(self) return {Research = self.Technology} end,
                },
                {
                    UICode = "-CS l",
                    HelpText = "ingteb-utility.multiple-research",
                    IsAvailable = function(self)
                        return self.Technology and self.Technology.IsNextGeneration
                    end,
                    Action = function(self)
                        return {Research = self.Technology, Multiple = true}
                    end,
                },
                -- {
                --     UICode = "--- r",
                --     HelpText = "ingteb-utility.create-reminder-task",
                --     Action = function(self) return {ReminderTask = self} end,
                -- },
            }
        end,
    },

    Required = {
        get = function(self)
            return RequiredThings:new(self.NotResearchedTechnologiesForRecipe, self.Input)
        end,
    },
}

function Recipe:GetCheapestWorkers()
    if self.HandCrafter then return Array:new{self.HandCrafter} end
    assert(release)
end

function Recipe:GetWorkerCraftingQueue()
    if self.HandCrafter then return Array:new{} end
    local worker = self.Category.Workers:Select(
        function(worker)
            if worker.Item then
                local result = self.CreatedBy --
                :ToArray(function(recipes) return recipes end) --
                :ConcatMany()
                assert(release)
            end
        end
    )
    assert(release)
end

function Recipe:IsBefore(other)
    if self == other then return false end
    local aOrder = self.OrderValue
    local bOrder = other.OrderValue
    return aOrder < bOrder
end

function Recipe:Refresh() self.cache.Recipe.OrderValue.IsValid = false end

function Recipe:SortAll() end

function Recipe:new(name, prototype, database)
    local self = self:adopt(self.base:new(prototype or game.recipe_prototypes[name], database))

    assert(release or self.Prototype.object_name == "LuaRecipePrototype")

    self.SpriteType = "recipe"
    self.IsHidden = false
    self.Time = self.Prototype.energy
    self.IsRefreshRequired = {Research = true, MainInventory = true}
    self.IsRecipe = true

    return self

end

return Recipe
