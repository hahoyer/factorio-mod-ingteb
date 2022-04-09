local Constants = require("Constants")
local Number = require("core.Number")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("ModuleEffect", Common)

Class.system.Properties = {
    Items = {
        cache = true,
        get = function(self)
            return self.Database.ItemsForModuleEffects[self.Name] --
            :Select(function(target) return self.Database:GetItem(nil, target) end)
        end,
    },

    Entities = {
        cache = true,
        get = function(self)
            return self.Database.EntitiesForModuleEffects[self.Name] --
            :Select(function(target) return self.Database:GetEntity(nil, target) end)
        end,
    },

    SpriteName = {
        cache = true,
        get = function(self)
            local item = self.Items --
            :Where(function(item) return item.Prototype.module_effects[self.Name] end):Top()
            if item and game.is_valid_sprite_path(item.SpriteName) then
                return item.SpriteName
            end

            log {
                "mod-issue.missing-item",
                self.Prototype.localised_name,
                "module_effect." .. self.Prototype.name,
            }
            return "utility/missing_icon"

        end,
    },

    UsefulLinks = {
        cache = true,
        get = function(self) return Array:new{self.Items, self.Entities} end,
    },

}

function Class:GetEffectHelp(effect)
    return {
        "",
        "[img=" .. self.SpriteName .. "] ",
        self.LocalisedName,
        " " .. Number:new(effect.bonus).FormatAsPercentWithSign,
    }
end

function Class:new(name, prototype, database)
    dassert(name)
    dassert(not prototype)

    local self = self:adopt(
        self.system.BaseClass:new(
            Common:CreatePrototype("ModuleEffect", name), database
        )
    )

    self.SpriteType = "item"

    function self:SortAll() end

    return self

end

return Class

