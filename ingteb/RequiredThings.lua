local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")

local RequiredThings = class:new("RequiredThings", nil)

function RequiredThings:new(technologies, stackOfGoods)
    local self = self:adopt{Technologies = technologies, StackOfGoods = Dictionary:new()}

    if stackOfGoods then
        stackOfGoods:Select(
            function(stack) self.StackOfGoods[stack.Goods.CommonKey] = stack:Clone() end
        )
    end
    return self
end

function RequiredThings:Any()
    return self.Technologies and self.Technologies:Any() or self.StackOfGoods:Any() --
end

function RequiredThings:Count()
    return (self.Technologies and self.Technologies:Count() or 0) + self.StackOfGoods:Count()
end

function RequiredThings:AddOption(option)
    if not self.Technologies then
        self.Technologies = option.Technologies
    elseif option.Technologies then
        self.Technologies = self.Technologies:Intersection(option.Technologies)
    else
        self.Technologies = Array:new()
    end

    option.StackOfGoods:Select(
        function(stack)
            if self.StackOfGoods[stack.Goods.CommonKey] then
                self.StackOfGoods[stack.Goods.CommonKey]:AddOption(stack)
            else
                self.StackOfGoods[stack.Goods.CommonKey] = stack:Clone()
            end
        end
    )
end

function RequiredThings:Except(other)
    local result = RequiredThings:new()
    if self.Technologies then result.Technologies = self.Technologies:Except(other.Technologies) end

    result.StackOfGoods = self.StackOfGoods:Except(other.StackOfGoods)

    return result
end

function RequiredThings:RemoveThings(other)
    if self.Technologies then self.Technologies = self.Technologies:Except(other.Technologies) end
    self.StackOfGoods = self.StackOfGoods:Except(other.StackOfGoods)
end

return RequiredThings

