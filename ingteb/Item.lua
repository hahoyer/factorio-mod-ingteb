local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")

local Item = Common:class("Item")

function Item:new(name, prototype, database)
    local self = Common:new(prototype or game.item_prototypes[name], database)
    self.object_name = Item.object_name
    self.SpriteType = "item"

    assert(self.Prototype.object_name == "LuaItemPrototype")

    self:properties{
        Entity = {
            cache = true,
            get = function()
                if self.Prototype.place_result then
                    return self.Database.GetEntity(self.Prototype.place_result.name)
                end
            end,
        },

        RecipeList = {
            cache = true,
            get = function()
                local entity = game.entity_prototypes[self.Prototype.name]

                return Dictionary:new(entity and entity.crafting_categories or {}) --
                :Concat(Dictionary:new(entity and entity.resource_categories or {})) --
                :Select(
                    function(_, category)
                        return self.Database.RecipesForCategory[category]
                    end
                )

                --    return self.Entity and self.Entity.RecipeList or Array:new{} 
            end,
        },

        OriginalUsedBy = {
            get = function()
                local names = self.Database:GetItemUsedBy(self.Prototype.name)
                if not names then return Dictionary:new{} end

                return names --
                :Select(
                    function(value, key)
                        assert(key == "crafting.crafting")
                        return value --
                        :Select(
                            function(value)
                                return self.Database:GetRecipe(value)
                            end
                        )
                    end
                )
            end,
        },

        OriginalCreatedBy = {
            get = function()
                local names = self.Database:GetItemCreatedBy(self.Prototype.name)
                if not names then return Dictionary:new{} end

                return names --
                :Select(
                    function(value, key)
                        assert(key == "crafting.crafting")
                        return value --
                        :Select(
                            function(value)
                                return self.Database:GetRecipe(value)
                            end
                        )
                    end
                )

            end,
        },
    }

    local function Sort(target)
        local targetArray = target:ToArray(
            function(value, key) return {Value = value, Key = key} end
        )
        targetArray:Sort(
            function(a, b)
                if a == b then return false end
                local aOrder = a.Value:Select(function(recipe) return recipe.Order end):Sum()
                local bOrder = b.Value:Select(function(recipe) return recipe.Order end):Sum()
                if aOrder ~= bOrder then return aOrder > bOrder end

                local aSubOrder = a.Value:Select(
                    function(recipe) return recipe.SubOrder end
                ):Sum()
                local bSubOrder = b.Value:Select(
                    function(recipe) return recipe.SubOrder end
                ):Sum()
                return aSubOrder > bSubOrder

            end
        )

        return targetArray:ToDictionary(
            function(value)
                value.Value:Sort(function(a, b) return a:IsBefore(b) end)
                return value
            end
        )

    end

    function self:SortAll()
        if not self.CreatedBy then self.CreatedBy = self.OriginalCreatedBy end
        if not self.UsedBy then self.UsedBy = self.OriginalUsedBy end
        self.CreatedBy = Sort(self.CreatedBy)
        self.UsedBy = Sort(self.UsedBy)
    end

    return self

end

return Item
