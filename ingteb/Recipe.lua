local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local UI = require("core.UI")

local Recipe = Common:class("Recipe")

function Recipe:new(name, prototype, database)
    local self = Common:new(prototype or game.recipe_prototypes[name], database)
    self.object_name = Recipe.object_name

    assert(self.Prototype.object_name == "LuaRecipePrototype")

    self.TypeOrder = 1
    self.SpriteType = "recipe"
    self.TechnologyPrototypes = Array:new()
    self.IsHidden = false
    self.IsDynamic = true
    self.Time = self.Prototype.energy

    self:properties{

        FunctionHelp = {
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
        },

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
                return self.Category.Workers:Where(
                    function(worker) return worker.Name == "character" end
                ):Top()
            end,
        },

        SpriteStyle = {
            get = function()
                if not self.IsResearched then return false end
                if self.NumberOnSprite then return true end
            end,
        },

        Output = {
            cache = true,
            get = function()

                return Array:new(self.Prototype.products) --
                :Select(
                    function(product)
                        local result = database:GetStackOfGoods(product)
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
                        local result = database:GetStackOfGoods(ingredient)
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

    function self:Refresh() self.cache.OrderValue.IsValid = false end

    function self:SortAll() end

    function self:GetHandCraftingOrder(event)
        if (UI.IsMouseCode(event, "A-- l") --
        or UI.IsMouseCode(event, "A-- r") --
        or UI.IsMouseCode(event, "--S l")) --
        and self.HandCrafter and self.NumberOnSprite then
            local amount = 0
            if event.shift then
                amount = game.players[event.player_index].get_craftable_count(self.Name)
            elseif event.button == defines.mouse_button_type.left then
                amount = 1
            elseif event.button == defines.mouse_button_type.right then
                amount = 5
            else
                return
            end
            return {count = amount, recipe = self.Name}
        end
    end

    return self

end

return Recipe
