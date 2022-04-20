local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local Goods = require("ingteb.Goods")
local class = require("core.class")

local Class = class:new("Fluid", Goods, {
    SpriteType = { get = function(self) return "fluid" end },
})

function Class:new(name, prototype, database)
    local self = self:adopt(
        self.system.BaseClass:new(prototype or game.fluid_prototypes[name], database)
    )
    dassert(self.Prototype.object_name == "LuaFluidPrototype")
    return self
end

return Class
