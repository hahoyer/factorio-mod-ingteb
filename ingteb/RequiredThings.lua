local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")

local RequiredThings = class:new("RequiredThings", nil)

function RequiredThings:new(technologies, stackOfGoods)
    local self = self:adopt{
        Technologies = technologies or Array:new{}, 
        StackOfGoods = Dictionary:new()
    }

    if stackOfGoods then
        stackOfGoods:Select(
            function(stack) 
                local key = stack.Goods and stack.Goods.CommonKey or stack.CommonKey
                self.StackOfGoods[key] = stack:Clone() 
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
    return self.Technologies:Concat(self.StackOfGoods:ToArray())
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

