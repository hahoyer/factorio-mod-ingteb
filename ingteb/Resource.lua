local Constants = require("Constants")
local Number = require "core.Number"
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local RequiredThings = require("ingteb.RequiredThings")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("Resource", Common)

Class.system.Properties = {
    SpriteType = { get = function(self) return "entity" end },
    TypeStringForLocalisation = { get = function(self) return "ingteb-type-name.resource" end },
    UsedBy = {
        cache = true,
        get = function(self) return self.Database:GetUsedByRecipes(self.Prototype) end,
    },

    IsResource = { get = function(self) return true end, },
}

function Class:SortAll() end

function Class:CreateStack(amounts) return self.Database:CreateStackFromGoods(self, amounts) end

function Class:new(name, prototype, database)
    local self = self:adopt(
        self.system.BaseClass:new(
            prototype or game.entity_prototypes[name], database
        )
    )

    if name then self.Name = name end

    dassert(self.Prototype.object_name == "LuaEntityPrototype")
    dassert(self.Prototype.type == "resource")


    return self

end

return Class
