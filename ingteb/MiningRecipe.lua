local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require "ingteb.RecipeCommon"
local class = require("core.class")
local RequiredThings = require("ingteb.RequiredThings")

local MiningRecipe = class:new("MiningRecipe", Common)

local function GetCategoryAndRegister(self, domain, category)
    local result = self.Database:GetCategory(domain .. "." .. category)
    return result
end

MiningRecipe.system.Properties = { --
    Required = {get = function(self) return RequiredThings:new() end},
}

function MiningRecipe:new(name, prototype, database)
    local self = self:adopt(
        self.system.BaseClass:new(
            prototype or game.entity_prototypes[name], database
        )
    )

    self.SpriteType = "entity"
    self.Time = self.Prototype.mineable_properties.mining_time
    self.IsHidden = true
    self.TypeStringForLocalisation = "ingteb-utility.title-mining-recipe"

    local configuration = self.Prototype.mineable_properties
    dassert(configuration and configuration.minable)

    local domain = "mining"
    if not self.Prototype.resource_category then domain = "hand-mining" end
    if configuration.required_fluid then domain = "fluid-mining" end
    local category = self.Prototype.resource_category or "steel-axe"

    self.Category = GetCategoryAndRegister(self, domain, category)

    local resource = self.Database:GetEntity(nil, self.Prototype)
    resource.UsedBy:AppendForKey(self.Category.Name, self)

    self.RawInput = {{type = "resource", value = resource}}
    local configuration = self.Prototype.mineable_properties
    if configuration.required_fluid then
        table.insert(
            self.RawInput, {
                type = "fluid",
                name = configuration.required_fluid,
                amount = configuration.fluid_amount,
            }
        )
    end

    self.RawOutput = configuration.products

    function self:IsBefore(other)
        if self == other then return false end
        return self.OrderValue < other.OrderValue
    end

    function self:SortAll() end

    return self
end

return MiningRecipe
