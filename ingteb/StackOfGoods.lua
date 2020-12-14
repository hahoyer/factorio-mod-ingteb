local Constants = require("Constants")
local Common = require("Common")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")

local StackOfGoods = class:new(
    "StackOfGoods", Common, {
        NumberOnSprite = {
            cache = true,
            get = function(self)
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
        ClickTarget = {get = function(self) return self.Goods.ClickTarget end},
        CommonKey = {
            get = function(self)
                return self.Goods.CommonKey .. "/" .. self:GetAmountsKey()
            end,
        },
        SpriteName = {get = function(self) return self.Goods.SpriteName end},

        AdditionalHelp = {
            get = function(self)
                local result = self.inherited.StackOfGoods.AdditionalHelp.get(self) --
                if self.Goods then result:AppendMany(self.Goods.AdditionalHelp) end
                return result
            end,
        },

        IsRefreshRequired = {
            get = function(self)
                return self.Goods and self.Goods.IsRefreshRequired or nil
            end,
        },

        SpecialFunctions = {
            get = function(self)
                local result = self.inherited.StackOfGoods.SpecialFunctions.get(self)
                if self.Goods and self.Goods.SpecialFunctions then
                    result:AppendMany(self.Goods.SpecialFunctions)
                end
                return result
            end,
        },
    }

)

function StackOfGoods:new(goods, amounts, database)
    assert(release or goods)
    local self = self:adopt(self.base:new(goods.Prototype, database))
    assert(
        release or self.Prototype.object_name == "LuaItemPrototype" --
        or self.Prototype.object_name == "LuaFluidPrototype"
    )

    self.Goods = goods
    self.Amounts = amounts
    self.SpriteType = goods.SpriteType
    self.UsePercentage = self.Amounts.probability ~= nil

    function self:GetAmountsKey()
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

        return tostring(value * probability)

    end

    function self:Clone(patchAmountsFunction)
        local newAmounts = Dictionary:new(self.Amounds):Clone()
        patchAmountsFunction(newAmounts)
        return StackOfGoods:new(self.Goods, newAmounts, self.Database)
    end
    return self

end

return StackOfGoods
