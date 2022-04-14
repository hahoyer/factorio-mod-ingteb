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
            -- todo: present multiple items_to_place_this 
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

    -- not used at the moment
    EnergySourceProperties = {
        cache = true,
        get = function(self)
            local data = self.Prototype.electric_energy_source_prototype
                             or self.Prototype.fluid_energy_source_prototype
                             or self.Prototype.heat_energy_source_prototype
                             or self.Prototype.void_energy_source_prototype
            if data then --
                return --
            end
        end,
    },

    FuelCategories = {
        cache = true,
        get = function(self)
            return self.Categories --
            :Where(
                function(category)
                    return category.Domain == "burning" or category.Domain == "fluid-burning"
                end
            ) --
            :ToArray(
                function(category)
                    local name = category.Domain == "fluid-burning" and "fluid" or category.SubName
                    return self.Database:GetFuelCategory(name)
                end
            )
        end,
    },

    UsefulLinks = {
        cache = true,
        get = function(self)
            return Array:new{
                self.FuelCategories,
                self.Modules --
                :Where(function(value) return value end) --
                :ToArray(function(_, module) return module end),
            }
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
            local prototype = self.Prototype
            return prototype.type == "furnace" or prototype.type == "rocket-silo"
                       or prototype.fixed_recipe ~= nil
        end,
    },

    Required = {
        get = function(self)
            if self.Item then return self.Item.Required end
            if self.Prototype.name ~= "character" then dassert() end
            return RequiredThings:new()
        end,
    },

    Speed = {
        cache = true,
        get = function(self) --
            local result = 60.0
                               / (self.Prototype.rocket_rising_delay
                                   + self.Prototype.launch_wait_time)
            dassert(result and result > 0)
            return result
        end,
    },

    Modules = {
        cache = true,
        get = function(self)
            local result = Dictionary:new()
            local prototype = self.Prototype
            for name, value in pairs(prototype.allowed_effects or {}) do
                local items = self.Database.ItemsForModuleEffects[name]
                if items then
                    items:Select(
                        function(itemPrototype)
                            local item = self.Database:GetItem(nil, itemPrototype)
                            if result[item] ~= false then
                                result[item] = value
                            end
                        end
                    )
                end
            end
            return result
        end,
    },
}

function Class:SortAll() end

function Class:GetNumberOnSprite(category)
    if category.Domain == "burning" or category.Domain == "fluid-burning" then
        return self.Prototype.max_energy_usage * 60 / category.EnergyUsagePerSecond
    elseif category.Domain == "boiling" then
        return self.Prototype.target_temperature
    elseif category.Domain == "crafting" then
        return self.Prototype.crafting_speed
    elseif category.Domain == "mining" or category.Domain == "fluid-mining" or category.Name == "hand-mining.steel-axe" then
        return self.Prototype.mining_speed
    elseif category.Domain == "rocket-launch" then
        return self.Speed / category.Speed
    else
        dassert(false)
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
