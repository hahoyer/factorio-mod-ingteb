local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
require("Common")

function ItemSet(item, amounts, database)
    local self = Common(item.Name, item.Prototype, database)
    self.Item = item
    self.Amounts = amounts
    self.class_name = "ItemSet"
    self.SpriteType = item.SpriteType

    assert(self.Item)

    self.UsePercentage = self.Amounts.probability ~= nil

    self:addCachedProperty(
        "NumberOnSprite", function()
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
        end
    )

    self:addCachedProperty("SpriteName", function() return self.Item.SpriteName end)

    return self
end

