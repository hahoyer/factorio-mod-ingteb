local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")

local RequiredThings = class:new("RequiredThings", nil)

function RequiredThings:new(technologies, stackOfGoods)
    local self = self:adopt {
        Technologies = technologies or Array:new {},
        StackOfGoods = Dictionary:new()
    }

    if stackOfGoods then
        stackOfGoods:Select(
            function(stack) 
                self.StackOfGoods[stack.Goods.CommonKey] = stack:Clone()
             end
        )
    end
    return self
end

function RequiredThings:Any()
    return self.Technologies:Any() or self.StackOfGoods:Any() --
end

function RequiredThings:Count()
    return self.Technologies:Count() + self.StackOfGoods:Count()
end

function RequiredThings:GetData()
    local technologies = self.Technologies
        :ToArray()
        :ToGroup(function(value)
            return {
                Key = value.IsResearching and "Researching" or value.IsReady and "Edge" or "Next",
                Value = value
            }
        end)
    local stacks = self.StackOfGoods
        :ToArray()
        :ToGroup(function(stack)
            return {
                Key = type(stack.NumberOnSprite) == "number" and stack.NumberOnSprite < 0 and "Missing" or "Available",
                Value = stack
            }
        end)
    return Array:new
        {
            technologies.Researching,
            technologies.Edge,
            technologies.Next,
            stacks.Missing,
            stacks.Available
        }
        :Compact()
end

function RequiredThings:Except(other)
    local result = RequiredThings:new()
    result.Technologies = self.Technologies:Except(other.Technologies)

    result.StackOfGoods = self.StackOfGoods:Except(other.StackOfGoods)

    return result
end

function RequiredThings:RemoveThings(other)
    self.Technologies = self.Technologies:Except(other.Technologies)
    self.StackOfGoods = self.StackOfGoods:Except(other.StackOfGoods)
end

return RequiredThings
