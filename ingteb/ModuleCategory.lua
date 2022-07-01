local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")
local class = require("core.class")

local Class = class:new("ModuleCategory", Common)

-- todo: present limitations

Class.system.Properties = {
    SpriteType = { get = function(self) return "item" end },
    Items = {
        cache = true,
        get = function(self)
            return (self.Database.BackLinks.ItemsForModuleCategory[self.Name] or Array:new()) --
            :Select(function(target) return self.Database:Get(target) end)
        end,
    },

    Entities = {
        cache = true,
        get = function(self)
            local result = Dictionary:new()

            local items = self.Items --
            :Select(
                function(item)
                    item.ModuleTargets:Select(
                        function(value, entity)
                            if result[entity] ~= false then
                                result[entity] = value
                            end
                        end
                    )
                end
            )

            return result:ToArray(function(value, entity) return entity end)
        end,
    },

    SpriteName = {
        cache = true,
        get = function(self)
            local item = self.Items:Top()
            if item and game.is_valid_sprite_path(item.SpriteName) then
                return item.SpriteName
            end

            log {
                "mod-issue.missing-item",
                self.Prototype.localised_name,
                "module_category." .. self.Prototype.name,
            }
            return "utility/missing_icon"

        end,
    },

    UsefulLinks = {
        cache = true,
        get = function(self) return Array:new{self.Items, self.Entities} end,
    },

}

function Class:new(name, prototype, database)
    dassert(database)

    local self = self:adopt(
        self.system.BaseClass:new(
            prototype or game.module_category_prototypes[name], database
        )
    )

    function self:SortAll() end

    return self

end

return Class

