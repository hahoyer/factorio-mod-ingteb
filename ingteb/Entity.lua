local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local ValueCache = require("core.ValueCache")
require("ingteb.Common")

function Entity(name, prototype, database)
    local self = CommonThing(name, prototype, database)
    self.class_name = "Entity"
    self.SpriteType = "entity"

    function self:IsMatchingItem(product)
        return product.name == self.Name --
        and product.type == "item" --
        and product.amount == 1 --
    end

    function self:Collect(entities, domain, dictionary)
        if not entities then return end
        for key, _ in pairs(entities) do self:AppendForKey(key .. " " .. domain, dictionary) end
    end

    function self:IsMineable()
        local p = self.Prototype
        if not p.mineable_properties --
        or not p.mineable_properties.minable --
        or not p.mineable_properties.products --
        then return end
        return not p.items_to_place_this 
    end

    function self:Setup()
        if self.Name:find("mini") then --
            local x = y
        end
        if self.Name == "coal" then --
            local x = y
        end

        if self:IsMineable() then self.Database:CreateMiningRecipe(self) end

        self:Collect(self.Prototype.resource_categories, "mining", self.Database.WorkingEntities)
        if #self.Prototype.fluidbox_prototypes > 0 then
            self:Collect(self.Prototype.resource_categories, "fluid mining", self.Database.WorkingEntities)
        end
        self:Collect(self.Prototype.crafting_categories, "crafting", self.Database.WorkingEntities)

    end

    return self
end

