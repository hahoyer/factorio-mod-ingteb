local Constants = require("Constants")
local Common = require("Common")

local ItemSet = Common:class("ItemSet")

function ItemSet:new(item, amounts, database)
    assert(item)
    local self = Common:new(item.Prototype, database)
    self.object_name = ItemSet.object_name
    assert(self.Prototype.object_name == "LuaItemPrototype")

    self.Item = item
    self.Amounts = amounts
    self.SpriteType = item.SpriteType
    self.UsePercentage = self.Amounts.probability ~= nil

    self:properties{
        NumberOnSprite = {
            cache = true,
            get = function()
                local amounts = self.Amounts
                if not amounts then return end

                local probability = (amounts.probability or 1)
                local value = amounts.value

                if not value then
                    if not amounts.min then
                        value = amounts.max
                    elseif not amounts.max then
                        value = amounts.min
                    else
                        value = (amounts.max + amounts.min) / 2
                    end
                elseif type(value) ~= "number" then
                    return
                end

                return value * probability
            end,
        },
        
        SpriteName = {get = function() return self.Item.SpriteName end},

    }

    return self

end

return ItemSet
