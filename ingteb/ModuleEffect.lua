local Constants = require("Constants")
local Helper = require "ingteb.Helper"
local Number = require("core.Number")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("ModuleEffect", Common)

Class.system.Properties = {
    SpriteType = { get = function(self) return "item" end },
    BackLinkType = { get = function(self) return "module_effect" end },
    Items = { get = function(self) return self:GetBackLinkArray("module_effects", "item") end, },
    Entities = { get = function(self) return self:GetBackLinkArray("allowed_effects", "entity") end, },

    SpriteName = {
        cache = true,
        get = function(self)
            local item = self.Items--
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
        get = function(self) return Array:new { self.Items, self.Entities } end,
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
            Helper.CreatePrototypeProxy { type = "ModuleEffect", name = name }, database
        )
    )

    function self:SortAll() end

    return self

end

return Class
