local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local RequiredThings = require("ingteb.RequiredThings")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("Entity", Common)

Class.system.Properties = {
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
            local xreturn = self.Database.Proxies.Category -- 
            :Where(
                function(category)
                    local workers = self.Database.WorkersForCategory[category.Name]
                    return workers
                               and workers:Any(function(worker)
                            return worker == self.Prototype
                        end)
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
            if not self.Item then return inherited end
            local result = Array:new{
                {
                    UICode = "--- l", --
                    Action = function(self) return {Presenting = self.Item} end,
                },
                {
                    UICode = "-C- l",
                    HelpText = "controls.smart-pipette",
                    Action = function(self)
                        return {Selecting = self.Item, Entity = self}
                    end,
                },
                {
                    UICode = "--- r",
                    IsRestricedTo = {Presentator = true, Remindor = true},
                    HelpText = "ingteb-utility.create-reminder-task",
                    Action = function(self) return {RemindorTask = self.Item} end,
                },
            }
            return result:Concat(inherited)
        end,
    },

    HasAutomaticRecipes = {
        cache = true,
        get = function(self)
            if self.Prototype.type == "furnace" or self.Prototype.type == "rocket-silo" then
                return true
            end
        end,
    },

    Required = {
        get = function(self)
            if self.Item then return self.Item.Required end
            if self.Prototype.name ~= "character" then dassert() end
            return RequiredThings:new()
        end,
    },

    NumberOnSprite = {
        get = function(self)
            return self.Prototype.mining_speed --
            or self.Prototype.crafting_speed -- 
            or self.Prototype.researching_speed -- 
            or self.Prototype.target_temperature -- 
        end,
    },

}

function Class:SortAll() end

function Class:GetNumberOnSprite(category)
    local result = self.NumberOnSprite
    if result then return result end
    if self.Prototype.type == "reactor" then
        return self.Prototype.max_energy_usage * 60 / category.EnergyUsagePerSecond
    end
end

function Class:new(name, prototype, database)
    local self = self:adopt(
        self.system.BaseClass:new(
            prototype or game.entity_prototypes[name], database
        )
    )
    self.SpriteType = "entity"
    if name then self.Name = name end

    if self.Name == "character" then self.TypeSubOrder = -1 end

    dassert(self.Prototype.object_name == "LuaEntityPrototype")

    -- ConditionalBreak(self.Prototype.target_temperature)

    self.UsedBy = Dictionary:new{}
    self.CreatedBy = Dictionary:new{}
    self.Amounts = {value = 1}
    self.HelpTextWhenUsedAsProduct = {"", self.RichTextName .. " ", self.Prototype.localised_name}

    if self.IsResource then
        self.TypeStringForLocalisation = "ingteb-utility.title-resource"
    else
        self.TypeStringForLocalisation = "ingteb-utility.title-entity"
    end
    return self

end

return Class
