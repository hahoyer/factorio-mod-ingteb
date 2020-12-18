local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")

local function CombineStackOfGoods(stack, otherStack)
    if not stack then return otherStack end
    assert(release)
end

local RequiredThings = class:new("RequiredThings", nil)

function RequiredThings:new(technologies, stackOfGoods)
    local self = self:adopt{Technologies = technologies, StackOfGoods = Dictionary:new()}

    if stackOfGoods then
        stackOfGoods:Select(
            function(stack)
                self.StackOfGoods[stack.Goods.CommonKey] =
                    CombineStackOfGoods(self.StackOfGoods[stack.Goods.CommonKey], stack)
            end
        )
    end
    return self
end

function RequiredThings:Any()
    return self.Technologies and self.Technologies:Any() or self.StackOfGoods:Any() --
end

function RequiredThings:Count()
    return (self.Technologies and self.Technologies:Count() or 0) --
               + self.StackOfGoods:Select(function(stack) return stack.Amounts.value or 0 end):Sum()
end

function RequiredThings:AddOption(option)
    self.Technologies = self.Technologies and self.Technologies:Intersection(option.Technologies)
                            or option.Technologies

    option.StackOfGoods:Select(
        function(stack)
            self.StackOfGoods[stack.Goods.CommonKey] =
                CombineStackOfGoods(self.StackOfGoods[stack.Goods.CommonKey], stack)
        end
    )
end

function RequiredThings:Except(other)
    local result = RequiredThings:new()
    if self.Technologies then result.Technologies = self.Technologies:Except(other.Technologies) end

    result.StackOfGoods = self.StackOfGoods:Except(other.StackOfGoods)

    return result
end

return RequiredThings

