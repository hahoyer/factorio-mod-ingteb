local Constants = require("Constants")
local Common = require("Common")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")

local StackOfGoods = class:new(
    "StackOfGoods", Common, {
        NumberOnSprite = {
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

        AdditionalAmountsHelp = {
            get = function(self)
                local amounts = self.Amounts
                local results = Array:new{}
                if amounts then
                    local line --
                    = (amounts.min and "min: " .. amounts.min .. ", " or "")
                          .. (amounts.max and "max: " .. amounts.max .. ", " or "")
                          .. (amounts.probability and amounts.probability ~= 1 and "probability: "
                              .. amounts.probability .. "%" or "")
                    if line ~= "" then results:Append(line) end
                end
                return results
            end,
        },

        CustomAdditionalHelp = {
            get = function(self)
                if self.GetCustomHelp then
                    return self:GetCustomHelp()
                else
                    return {}
                end
            end,
        },

        AdditionalHelp = {
            get = function(self)
                local result = self.inherited.StackOfGoods.AdditionalHelp.get(self) --
                if self.Goods then result:AppendMany(self.Goods.AdditionalHelp) end
                result:AppendMany(self.AdditionalAmountsHelp)
                result:AppendMany(self.CustomAdditionalHelp)
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
                local result = Array:new{
                    {
                        UICode = "--- r",
                        IsRestricedTo = {Presentator = true},
                        HelpText = "ingteb-utility.create-reminder-task",
                        Action = function(self)
                            return {RemindorTask = self.Goods, Amounts = self.Amounts}
                        end,
                    },
                }

                result:AppendMany(self.inherited.StackOfGoods.SpecialFunctions.get(self))
                if self.Goods and self.Goods.SpecialFunctions then
                    result:AppendMany(self.Goods.SpecialFunctions)
                end
                return result
            end,
        },

        UsePercentage = {
            get = function(self) return self.Amounts and self.Amounts.probability ~= nil end,
        },
    }

)

function StackOfGoods:GetAmountsKey()
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

function StackOfGoods:AddOption(other)
    local otherAmounts = other.Amounts

    if otherAmounts.value and self.Amounts.value and otherAmounts.value == self.Amounts.value then
        return
    end

    self.Amounts.min = math.min(
        otherAmounts.value or otherAmounts.min, self.Amounts.value or self.Amounts.min
    )

    self.Amounts.max = math.max(
        otherAmounts.value or otherAmounts.max, self.Amounts.value or self.Amounts.max
    )

    self.Amounts.value = nil
end

function StackOfGoods:Clone()
    local amounts = self.Amounts and Dictionary:new(self.Amounts):Clone() or nil
    return StackOfGoods:new(self.Goods, amounts, self.Database)
end

function StackOfGoods:new(goods, amounts, database)
    assert(goods)
    local self = self:adopt(self.base:new(goods.Prototype, database))
    assert(
        self.Prototype.object_name == "LuaItemPrototype" --
        or self.Prototype.object_name == "LuaFluidPrototype"
    )

    self.Goods = goods
    self.Amounts = amounts
    assert(not amounts or amounts.value or amounts.probability)
    self.SpriteType = goods.SpriteType

    return self

end

return StackOfGoods
