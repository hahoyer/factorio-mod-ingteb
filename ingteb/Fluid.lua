local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local Goods = require("ingteb.Goods")
local class = require("core.class")

local Fluid = class:new("Fluid", Goods)

function Fluid:new(name, prototype, database)
    local self = self:adopt(self.system.base:new(prototype or game.fluid_prototypes[name], database))
    self.SpriteType = "fluid"

    dassert(self.Prototype.object_name == "LuaFluidPrototype")

    return self

end

return Fluid
