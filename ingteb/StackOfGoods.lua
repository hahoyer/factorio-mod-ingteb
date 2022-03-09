local Constants = require("Constants")
local Common = require("Common")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")

local Class = class:new(
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
                    local line = Array:new{}
                    local catalyst = amounts.catalyst_amount or 0

                    if amounts.min or amounts.max then
                        line:AppendMany{
                            ", ",
                            ((amounts.min or amounts.value) - catalyst) .. " - "
                                .. ((amounts.max or amounts.value) - catalyst),
                        }
                    end

                    if amounts.probability and amounts.probability ~= 1 then
                        line:AppendMany{
                            ", ",
                            {"description.probability"},
                            ": " .. amounts.probability * 100 .. "%",
                        }
                    end
                    if amounts.temperature then
                        line:AppendMany{
                            ", ",
                            {"description.temperature"},
                            ": " .. amounts.temperature,
                        }
                    end
                    if amounts.catalyst_amount then
                        line:AppendMany{
                            ", ",
                            {"description.catalyst_amount"},
                            ": " .. amounts.catalyst_amount,
                        }
                    end
                    if line:Any() then
                        line[1] = ""
                        results:Append(line)
                    end
                end
                return results
            end,
        },

        FormatedAmounts = {
            get = function(self)
                local amounts = self.Amounts
                local result = ""
                if amounts then
                    local catalyst = amounts.catalyst_amount or 0
                    local showPlus

                    if amounts.value and amounts.value > catalyst then
                        result = result .. (amounts.value - catalyst)
                        showPlus = true
                    end

                    if amounts.min or amounts.max then
                        result = result .. --
                        ((amounts.min or amounts.value) - catalyst) .. --
                        " - " .. --
                        ((amounts.max or amounts.value) - catalyst)
                        showPlus = true
                    end

                    if amounts.probability and amounts.probability ~= 1 then
                        result = result .. "(" .. amounts.probability * 100 .. "%)"
                        showPlus = true
                    end

                    if amounts.catalyst_amount then
                        if showPlus then result = result .. "+" end
                        result = result .. "[" .. amounts.catalyst_amount .. "]"
                    end
                    
                    if amounts.temperature then
                        result = result .. "(" .. amounts.temperature .. "°)"
                    end
                end
                return result
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

        HelpTextWhenUsedAsComponent = {
            get = function(self)
                local color
                local amounts = self.Amounts.value
                local counts = self.Goods.PlayerCounts or {Available = 0, Crafting = 0}
                if counts.Available >= self.Amounts.value then
                    color = "white"
                elseif counts.Crafting >= self.Amounts.value then
                    color = "green"
                else
                    color = "red"
                    amounts = counts.Available .. "/" .. amounts
                end

                return {
                    "",
                    self.Goods.RichTextName .. " [color=" .. color .. "][font=default-bold]"
                        .. amounts .. " x[/font] ",
                    self.Goods.Prototype.localised_name,
                    "[/color]",
                }
            end,
        },
        HelpTextWhenUsedAsProduct = {
            get = function(self)
                return {
                    "",
                    self.Goods.RichTextName .. " [font=default-bold]" .. self.FormatedAmounts
                        .. " x[/font] ",
                    self.Goods.Prototype.localised_name,

                }
            end,
        },
    }

)

function Class:GetAmountsKey()
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

function Class:AddOption(other)
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

function Class:Clone(factor)
    local amounts = self.Amounts and Dictionary:new(self.Amounts):Clone() or nil
    if factor then
        if amounts then
            if amounts.value then amounts.value = amounts.value * factor end
            if amounts.min then amounts.min = amounts.min * factor end
            if amounts.max then amounts.max = amounts.max * factor end
        else
            amounts = {value = factor}
        end
    end
    return Class:new(self.Goods, amounts, self.Database)
end

function Class:new(goods, amounts, database)
    dassert(goods)
    local self = self:adopt(self.system.BaseClass:new(goods.Prototype, database))
    dassert(
        self.Prototype.object_name == "LuaItemPrototype" --
        or self.Prototype.object_name == "LuaFluidPrototype"
    )

    self.Goods = goods
    self.Amounts = amounts
    dassert(not amounts or amounts.value or amounts.probability)
    self.SpriteType = goods.SpriteType

    return self

end

return Class
