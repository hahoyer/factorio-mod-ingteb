local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local ignore
local Technology = class:new(
    "Technology", Common, {
        Amount = {
            cache = true,
            get = function(self) --
                local formula = self.Prototype.research_unit_count_formula
                if formula then
                    local level = self.Prototype.level
                    local result = game.evaluate_expression(formula, {L = level, l = level})
                    return result
                else
                    return self.Prototype.research_unit_count
                end
            end,
        },

        Ingredients = {
            get = function(self) --
                return Array:new(self.Prototype.research_unit_ingredients) --
                :Select(
                    function(tag, index)
                        local result = self.Database:GetStackOfGoods(tag)
                        result.Goods.UsedBy:AppendForKey(" researching", self)
                        result.Source = {Technology = self, IngredientIndex = index}
                        return result
                    end
                ) --
            end,

        },

        Input = {
            get = function(self) --
                return self.Ingredients:Select(
                    function(stack)
                        return stack:Clone(
                            function(amounts)
                                amounts.value = amounts.value * self.Amount
                            end
                        )
                    end
                ) --
            end,
        },

        NumberOnSprite = {
            get = function(self) --
                if self.Prototype.level and self.Prototype.max_level > 1 then
                    return self.Prototype.level
                end
            end,
        },

        SpriteStyle = {
            get = function(self)
                if self.IsResearchedOrResearching then return end
                return self.IsReady
            end,
        },
        IsResearched = {
            get = function(self)
                return self.Database.Player.force.technologies[self.Prototype.name].researched
                           == true
            end,
        },
        IsResearchedOrResearching = {
            get = function(self) return self.IsResearched or self.IsResearching end,
        },

        IsNextGeneration = {
            get = function(self)
                return not (self.IsResearched or self.IsReady or self.IsResearching)
            end,
        },

        IsResearching = {
            get = function(self)
                local queue = self.Database.Player.force.research_queue
                for index = 1, #queue do
                    if queue[index].name == self.Prototype.name then return true end
                end
            end,
        },
        IsReady = {
            get = function(self)
                return not self.IsResearchedOrResearching and self.Prerequisites:All(
                    function(technology)
                        return technology.IsResearchedOrResearching
                    end
                )
            end,
        },

        Prerequisites = {
            get = function(self)
                return Dictionary:new(self.Prototype.prerequisites) --
                :ToArray() --
                :Select(
                    function(technology)
                        return self.Database:GetTechnology(nil, technology)
                    end
                )
            end,
        },

        TopReadyPrerequisite = {
            get = function(self)
                if self.IsResearchedOrResearching then return end
                if self.IsReady then return self end
                for _, technology in pairs(self.Prerequisites) do
                    local result = technology.TopReadyPrerequisite
                    if result then return result end
                end
            end,
        },

        NotResearchedPrerequisitesRaw = {
            get = function(self)
                local result = Array:new{}
                if self.IsResearched then return result end
                for _, technology in pairs(self.Prerequisites) do
                    result:AppendMany(technology.NotResearchedPrerequisitesRaw)
                end
                result:Append(self)
                return result
            end,
        },

        NotResearchedPrerequisites = {
            get = function(self)
                return self.NotResearchedPrerequisitesRaw --
                :GetUniqueEntries(function(value) return value.Name end)
            end,
        },

        Enables = {
            cache = true,
            get = function(self)
                local enabledTechnologies =
                    self.Database.EnabledTechnologiesForTechnology[self.Prototype.name]
                if enabledTechnologies then
                    return enabledTechnologies --
                    :Select(
                        function(technology)
                            return self.Database:GetTechnology(nil, technology)
                        end
                    )
                else
                    return Array:new{}
                end
            end,
        },

        EnabledRecipes = {
            cache = true,
            get = function(self)
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
            get = function(self)
                return Dictionary:new(self.Prototype.effects) --
                :Select(
                    function(effect)
                        if effect.type == "unlock-recipe" then
                            return self.Database:GetRecipe(effect.recipe)
                        end
                        return self.Database:GetBonusFromEffect(effect)
                    end
                )
            end,
        },

        SpecialFunctions = {
            get = function(self) --
                local result = self.inherited.Technology.SpecialFunctions:get(self)
                return result:Concat{
                    {
                        UICode = "-C- l",
                        HelpText = "gui-technology-preview.start-research",
                        IsAvailable = function(self) return self.IsReady end,
                        Action = function(self) return {Research = self} end,
                    },
                    {
                        UICode = "-CS l",
                        HelpText = "ingteb-utility.multiple-research",
                        IsAvailable = function(self)
                            return self.IsNextGeneration
                        end,
                        Action = function(self)
                            return {Research = self, Multiple = true}
                        end,
                    },
                    -- {
                    --     UICode = "--- r",
                    --     IsRestricedTo = {Presentator = true},
                    --     HelpText = "ingteb-utility.create-reminder-task",
                    --     Action = function(self) return {RemindorTask = self} end,
                    -- },
                }
            end,
        },
    }
)

local function AddResearch(player, name)
    if player.force.research_queue_enabled or #player.force.research_queue == 0 then
        return player.force.add_research(name)
    end
end

function Technology:BeginMulipleQueueResearch()
    local player = self.Database.Player
    local queued = Array:new{}
    local message = "ingteb-utility.research-no-ready-prerequisite"
    repeat
        local ready = self.TopReadyPrerequisite
        if ready then message = "ingteb-utility.not-added-to-research-queue" end
        local added = ready and AddResearch(player, ready.Name)
        if added then queued:Append(ready) end

    until not added

    queued:Select(
        function(technology)
            self.Database:Print(
                player,
                    {"ingteb-utility.added-to-research-queue", technology.Prototype.localised_name}
            )
            technology:Refresh()
        end
    )
    if not queued:Any() then return {message, self.Prototype.localised_name} end
end

function Technology:BeginDirectQueueResearch()
    local player = self.Database.Player
    local added = AddResearch(player, self.Name)
    if added then
        self.Database:Print(
            player, {"ingteb-utility.added-to-research-queue", self.Prototype.localised_name}
        )
        self:Refresh()
    else
        self.Database:Print(
            player, {"ingteb-utility.not-added-to-research-queue", self.Prototype.localised_name}
        )
    end
end

function Technology:Refresh() self.EnabledRecipes:Select(function(recipe) recipe:Refresh() end) end

function Technology:IsBefore(other)
    if self == other then return false end
    if self.TypeOrder ~= other.TypeOrder then return self.TypeOrder < other.TypeOrder end
    if self.IsResearched ~= other.IsResearched then return self.IsResearched end
    if self.IsReady ~= other.IsReady then return self.IsReady end
    return self.Prototype.order < other.Prototype.order
end

function Technology:SortAll()
    if not self.CreatedBy then self.CreatedBy = self.OriginalCreatedBy end
    if not self.UsedBy then self.UsedBy = self.OriginalUsedBy end
end

function Technology:new(name, prototype, database)
    local self = self:adopt(self.base:new(prototype or game.technology_prototypes[name], database))

    assert(self.Prototype.object_name == "LuaTechnologyPrototype")

    self.SpriteType = "technology"
    self.Time = self.Prototype.research_unit_energy
    self.IsRefreshRequired = {Research = true}
    self.TypeStringForLocalisation = "ingteb-utility.title-technology"

    return self

end

return Technology
