local Common = require "ingteb.RecipeCommon"
local class = require("core.class")

local Class = class:new("MiningRecipe", Common)

function Class:new(name, prototype, database)
    local self = self:adopt(self.system.BaseClass:new(name, prototype, database))
    self.Domain = "Mining"
    return self
end

return Class
