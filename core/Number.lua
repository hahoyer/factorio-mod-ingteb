local class = require("core.class")
local Class = class:new("Number")

local SmallUnits = {"m", "µ", "n", "p", "f", "a", "z", "y"}
local BigUnits = {"k", "M", "G", "T", "P", "E", "Z", "Y"}

Class.system.Properties = {
    Size = {
        cache = true,
        get = function(self)
            local value = self.Value
            local result = 2
            if value == 0 then return result end

            if value < 0 then value = -value end

            while value < 100 do
                result = result - 1
                value = value * 10
            end

            while value >= 1000 do
                result = result + 1
                value = value / 10
            end

            return result
        end,
    },

    Digits = {
        cache = true,
        get = function(self)

            local value = self.Value
            if value == 0 then return "0" end

            if value < 0 then value = -value end
            while value < 100 do value = value * 10 end
            while value >= 1000 do value = value / 10 end
            return string.format("%03d", math.floor(value + 0.5))
        end,
    },

    Sign = {cache = true, get = function(self) return self.Value < 0 and "-" or "" end},
    AbsoluteValue = {cache = true, get = function(self) return self.Value < 0 and -self.Value or self.Value end},

    Unit = {
        cache = true,
        get = function(self)
            local unitIndex = math.floor(self.Size / 3)
            if unitIndex < 0 then
                return SmallUnits[-unitIndex]
            elseif unitIndex > 0 then
                return BigUnits[unitIndex]
            else
                return ""
            end
        end,
    },

    IntegerPart = {
        cache = true,
        get = function(self)
            if self.Value == 0 then return "0" end
            local digits = self.Digits
            local integer = digits:sub(1, self.Size % 3 + 1)
            return integer
        end,
    },
    Decimals = {
        cache = true,
        get = function(self)
            if self.Value == 0 then return "" end

            local subSize = self.Size % 3
            local digits = self.Digits
            local decimals = ""

            if digits:sub(3) ~= "0" then
                if subSize == 0 then
                    decimals = digits:sub(2, 3)
                elseif subSize == 1 then
                    decimals = digits:sub(3, 3)
                end
            elseif subSize == 0 then
                if digits:sub(2, 2) ~= "0" then decimals = digits:sub(2, 2) end
            end
            if decimals ~= "" then decimals = "." .. decimals end
            return decimals
        end,
    },
    Format3Digits = {
        cache = true,
        get = function(self)
            return self.Sign .. self.IntegerPart .. self.Decimals .. self.Unit
        end,
    },
    FormatAsPercent = {
        cache = true,
        get = function(self)
            if self.AbsoluteValue < 0.01 then 
                return Class:new(self.Value * 1000).Format3Digits .. "%%"
            end
            return Class:new(self.Value * 100).Format3Digits .. "%"
        end,
    },
    FormatAsPercentWithSign = {
        cache = true,
        get = function(self)
            return self.Sign .. Class:new(self.AbsoluteValue).FormatAsPercent
        end,
    },
}

function Class:new(target)
    local result = self:adopt{Value = target}
    return result
end

function Unittest()

    local targets = {
        {0, "0"},
        {1, "1"},
        {-1, "-1"},
        {11, "11"},
        {111, "111"},
        {1111, "1.11k"},
        {1110, "1.11k"},
        {1100, "1.1k"},
        {1000, "1k"},
        {12000, "12k"},
        {120000, "120k"},
        {1200000, "1.2M"},
        {11.2, "11.2"},
        {1.212, "1.21"},
        {0.00212, "2.12m"},
        {0.0000021, "2.1µ"},
        {0.000000002, "2n"},
        {0.000000000002002, "2p"},
    }

    for _, value in ipairs(targets) do
        local target = Class:new(value[1])
        local result = target.Format3Digits
        dassert(result == value[2])
    end
    return true
end

dassert(Unittest())

function Class.Format3Digits(target) return Class:new(target).Format3Digits end

return Class
