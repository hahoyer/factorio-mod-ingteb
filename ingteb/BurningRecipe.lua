local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require "ingteb.RecipeCommon"
local class = require("core.class")

local Class = class:new("BurningRecipe", Common)

Class.system.Properties = {
    Duration = { get = function(self) return self.Prototype.fuel_value end },
}

function Class:new(name, prototype, database)
    dassert(not name)
    dassert(prototype)
    dassert(database)

    local self = self:adopt(self.system.BaseClass:new(nil, prototype, database))
    self.IsFluid = prototype.object_name == "LuaFluidPrototype"


    return self
end

return Class
