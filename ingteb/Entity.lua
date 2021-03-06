local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local RequiredThings = require("ingteb.RequiredThings")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Entity = class:new("Entity", Common)

Entity.system.Properties = {
    SpriteName = {
        get = function(self)
            -- special entity for handmining
            if self.Name == "(hand-miner)" then return "technology/steel-axe" end
            return self.inherited.Entity.SpriteName.get(self)
        end,
    },

    -- ClickTarget = {
    --    get = function(self) return self.Item and self.Item.ClickTarget or self.CommonKey end,
    -- },

    Item = {
        cache = true,
        get = function(self)
            local place = self.Prototype.items_to_place_this
            if not place or #place == 0 then return end
            dassert(Array:new(place):All(function(p) return p.name == place[1].name end))
            return self.Database:GetItem(place[1].name)
        end,
    },

    IsResource = {
        cache = true,
        get = function(self)
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
        get = function(self)
            -- if self.Name == "big-processing-machine" then __DebugAdapter.breakpoint() end
            local xreturn = self.Database.Proxies.Category -- 
            :Where(
                function(category)
                    local domain = category.Domain
                    local list = {}
                    if domain == "mining" or domain == "fluid-mining" then
                        list = self.Prototype.resource_categories
                    elseif domain == "crafting" then
                        list = self.Prototype.crafting_categories
                    elseif domain == "hand-mining" then
                        return self.Name == "character"
                    elseif domain == "researching" then
                        return self.Prototype.lab_inputs
                    elseif domain == "boiling" then
                        return self.Prototype.type == "boiler"
                    else
                        dassert()
                    end
                    return list and list[category.SubName]
                end
            ) --
            return xreturn
        end,
    },

    RecipeList = {
        cache = true,
        get = function(self)
            return self.Categories --
            :Select(function(category) return category.RecipeList end) --
            :Where(function(recipes) return recipes:Any() end) --
        end,
    },

    SpecialFunctions = {
        get = function(self)
            local inherited = self.inherited.Entity.SpecialFunctions.get(self)
            local result = Array:new{
                {
                    UICode = "--- l", --
                    IsAvailable = function(self) return self.Item end,
                    Action = function(self) return {Presenting = self.Item} end,
                },
                {
                    UICode = "--- r",
                    IsRestricedTo = {Presentator = true, Remindor = true},
                    HelpText = "ingteb-utility.create-reminder-task",
                    IsAvailable = function(self) return self.Item end,
                    Action = function(self) return {RemindorTask = self.Item} end,
                },
            }
            return result:Concat(inherited)
        end,
    },

    Required = {
        get = function(self)
            if self.Item then return self.Item.Required end
            if self.Prototype.name ~= "character" then dassert() end
            return RequiredThings:new()
        end,
    },
}

function Entity:SortAll() end

function Entity:new(name, prototype, database)
    local self = self:adopt(
        self.system.BaseClass:new(prototype or game.entity_prototypes[name], database)
    )
    self.SpriteType = "entity"
    if name then self.Name = name end

    if self.Name == "character" then self.TypeSubOrder = -1 end

    dassert(self.Prototype.object_name == "LuaEntityPrototype")

    self.NumberOnSprite --
    = self.Prototype.mining_speed --
    or self.Prototype.crafting_speed -- 
    or self.Prototype.researching_speed -- 

    self.UsedBy = Dictionary:new{}
    self.CreatedBy = Dictionary:new{}

    if self.IsResource then
        self.TypeStringForLocalisation = "ingteb-utility.title-resource"
    else
        self.TypeStringForLocalisation = "ingteb-utility.title-entity"
    end
    return self

end

return Entity
