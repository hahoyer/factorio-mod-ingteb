local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")

local function OldRecipe(name, prototype, database)
    local result = Common(name, prototype, database)
    result.object_name = "Recipe"

    result.Time = result.Prototype.energy

    result.property.FunctionHelp = {
        get = function(self) --
            if self.IsResearched and self.NumberOnSprite then
                return {
                    "ingteb_utility.craft",
                    {"control-keys.alt"},
                    {"control-keys.control"},
                    {"control-keys.shift"},
                    {"control-keys.mouse-button-1-alt-1"},
                    {"control-keys.mouse-button-2-alt-1"},
                }
            end
        end,
    }

    function result:SortAll() end

    result.property.Order = {get = function(self) return self.IsResearched and 1 or 0 end}
    result.property.SubOrder = {
        get = function(self)
            return (not self.Technology or self.Technology.IsReady) and 1 or 0
        end,
    }

    function result:Refresh() self.cache.OrderValue.IsValid = false end

    result.IsDynamic = true

    function result:Setup()
        local category = self.Prototype.category .. " crafting"
        self.Category = self.Database.Categories[category]

        if self.IsHidden then return end

        self.Category.Recipes:Append(self)

        self.HandCrafter = self.Category.Workers:Where(
            function(worker) return worker.Name == "character" end
        ):Top()

        self.CraftingGroup = Dictionary:new{[self.Category.Name] = self}

        self.UsedBy = Dictionary:new{}
        self.CreatedBy = Dictionary:new{}
        self.RecipeList = Array:new{self.CraftingGroup}

    end

    return result
end

local x = OldRecipe

local Recipe = Common:class("Recipe")

function Recipe:new(name, prototype, database)
    local self = Common:new(prototype or game.recipe_prototypes[name], database)
    self.object_name = Recipe.object_name
    self.TypeOrder = 1
    self.SpriteType = "recipe"
    self.TechnologyPrototypes = Array:new()
    self.IsHidden = false

    assert(self.Prototype.object_name == "LuaRecipePrototype")

    self:properties{

        Technologies = {
            cache = true,
            get = function()
                return self.TechnologyPrototypes:Select(
                    function(prototype)
                        return self.Database:GetTechnology(nil, prototype)
                    end
                )
            end,
        },

        IsResearched = {
            get = function()
                return --
                not self.Technologies:Any() --
                    or self.Technologies:Any(
                        function(technology) return technology.IsResearched end
                    )
            end,
        },

        Technology = {
            get = function()
                if self.Technologies:Count() <= 1 then return self.Technologies:Top() end

                local researched = self.Technologies:Where(
                    function(technology) return technology.IsResearched end
                )
                if researched:Count() > 0 then return researched:Top() end

                local ready = self.Technologies:Where(
                    function(technology) return technology.IsReady end
                )
                if ready:Count() > 0 then return researched:Top() end

                return self.Technologies:Top()
            end,
        },

        OrderValue = {
            cache = true,
            get = function()
                return self.TypeOrder .. " " .. (self.IsResearched and "R" or "r") .. " "
                           .. (not self.IsResearched and self.Technology.IsReady and "R" or "r")
                           .. " " .. self.Prototype.group.order .. " "
                           .. self.Prototype.subgroup.order .. " " .. self.Prototype.order
            end,
        },

        NumberOnSprite = {
            get = function()
                if not self.HandCrafter then return end
                local result = global.Current.Player.get_craftable_count(self.Name)
                if result > 0 then return result end
            end,
        },

        Category = {
            cache = true,
            get = function()
                return self.Database.Proxies.Category["crafting." .. self.Prototype.category]
            end,
        },

        HandCrafter = {
            get = function()
                self.Category.Workers:Where(
                    function(worker) return worker.Name == "character" end
                ):Top()
            end,
        },

        SpriteStyle = {
            get = function()
                if not self.IsResearched then return "red_slot_button" end
                if self.NumberOnSprite then return "ingteb-light-button" end
            end,
        },

        Output = {
            cache = true,
            get = function()

                return Array:new(self.Prototype.products) --
                :Select(
                    function(product)
                        local result = database:GetItemSet(product)
                        if not result then self.IsHidden = true end
                        return result
                    end
                ) --
                :Where(function(value) return value end) --

            end,
        },
        Input = {
            cache = true,
            get = function()
                return Array:new(self.Prototype.ingredients) --
                :Select(
                    function(ingredient)
                        local result = database:GetItemSet(ingredient)
                        if not result then self.IsHidden = true end
                        return result
                    end
                ) --
                :Where(
                    function(value)
                        return not (value.flags and value.flags.hidden)
                    end
                ) --

            end,
        },
    }

    function self:IsBefore(other)
        if self == other then return false end
        return self.OrderValue < other.OrderValue
    end
    return self

end

return Recipe
