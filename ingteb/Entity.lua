local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")

local Entity = Common:class("Entity")

function Entity:new(name, prototype, database)
    local self = Common:new(prototype or game.entity_prototypes[name], database)
    self.object_name = Entity.object_name
    self.SpriteType = "entity"

    assert(self.Prototype.object_name == "LuaEntityPrototype")

    self.NumberOnSprite --
    = self.Prototype.mining_speed --
    or self.Prototype.crafting_speed -- 
    or self.Prototype.researching_speed -- 

    self:properties{
        ClickHandler = {get = function() return self.Item end},
        Item = {
            cache = true,
            get = function()
                local place = self.Prototype.items_to_place_this
                if not place or #place == 0 then return end
                assert(#place == 1)
                return self.Database:GetItem(place[1].name)
            end,
        },
        IsResource = {
            cache = true,
            get = function()
                local prototype = self.Prototype
                if not prototype.mineable_properties --
                or not prototype.mineable_properties.minable --
                    or not prototype.mineable_properties.products --
                then return end
                return not prototype.items_to_place_this
            end,
        },
        Categories = {
            cache = true,
            get = function()
                return self.Database.Proxies.Category -- 
                :Where(
                    function(category)
                        local domain = category.Domain
                        local list
                        if domain == "mining" or domain == "fluid mining" then
                            list = self.Prototype.resource_categories
                        elseif domain == "crafting" then
                            list = self.Prototype.crafting_categories
                        elseif domain == "hand mining" then
                            return
                        elseif domain == "researching" then
                            return self.Prototype.lab_inputs
                        else
                            assert()
                        end
                        return list and list[category.Name]
                    end
                ) --
                :Select(
                    function(category)
                        category.Workers:Append(self)
                        return category
                    end
                )
            end,
        },
        RecipeList = {
            cache = true,
            get = function()
                return self.Categories --
                :Select(function(category) return category.Recipes end) --
                :Where(function(recipes) return recipes:Any() end) --
            end,
        },
    }
    return self

end

function OldEntity(name, prototype, database)
    local self = Common(name, prototype, database)
    self.object_name = "Entity"
    self.UsedBy = Dictionary:new{}
    self.CreatedBy = Dictionary:new{}

    function self:SortAll() end

    function self:Setup()

        if self.IsResource then self.Database:CreateMiningRecipe(self) end

        self.Categories = self.Database.Categories -- 
        :Where(
            function(category)
                local domain = category.DomainName
                local list
                if domain == "mining" or domain == "fluid mining" then
                    list = self.Prototype.resource_categories
                elseif domain == "crafting" then
                    list = self.Prototype.crafting_categories
                elseif domain == "hand mining" then
                    return
                elseif domain == "researching" then
                    return self.Prototype.lab_inputs
                else
                    assert()
                end
                return list and list[category.Name]
            end
        ) --
        :Select(
            function(category)
                category.Workers:Append(self)
                return category
            end
        )

    end

    return self
end

return Entity
