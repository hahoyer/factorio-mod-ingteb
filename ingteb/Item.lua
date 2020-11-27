local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local Goods = require("ingteb.Goods")

local Item = Common:class("Item")

function Item:new(name, prototype, database)
    local self = Goods:new(prototype or game.item_prototypes[name], database)
    self.object_name = Item.object_name
    self.SpriteType = "item"

    assert(self.Prototype.object_name == "LuaItemPrototype")

    self:properties{
        Entity = {
            cache = true,
            get = function()
                if self.Prototype.place_result then
                    return self.Database:GetEntity(self.Prototype.place_result.name)
                end
            end,
        },
    }

    return self

end

return Item
