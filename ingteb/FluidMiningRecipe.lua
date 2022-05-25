local Common = require "ingteb.RecipeCommon"
local class = require("core.class")

local Class = class:new("FluidMiningRecipe", Common)

function Class:new(name, prototype, database)
    local self = self:adopt(self.system.BaseClass:new(name, prototype, database))
    self.Domain = "FluidMining"
    return self
end

return Class
