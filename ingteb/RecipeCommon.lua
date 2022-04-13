local Constants = require("Constants")
local Table = require("core.Table")
local RequiredThings = require("ingteb.RequiredThings")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("RecipeCommon", Common)

Class.system.Properties = {
    Workers = {
        get = function(self)
            local result = self.Category.Workers
            result:Sort(function(a, b) return a:IsBefore(b) end)
            return result
        end,
    },
    OrderValue = {
        cache = "player",
        get = function(self)
            return self.TypeOrder --
            .. " R R " --
            .. self.Prototype.group.order --
            .. " " .. self.Prototype.subgroup.order --
            .. " " .. self.Prototype.order
        end,
    },
    Required = {get = function(self) return RequiredThings:new(nil, self.Input) end},
}

function Class:new(prototype, database)
    local result = self:adopt(self.system.BaseClass:new(prototype, database))
    result.IsRecipe = true
    return result
end

return Class
