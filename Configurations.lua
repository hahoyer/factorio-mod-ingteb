local Table = require "core.Table"
local Array = Table.Array
local Dictionary = Table.Dictionary

local Result = {
    PresentatorFilter = Dictionary:new {
        Automatic = {
            Check = {
                Worker = function(self, target) return target.IsEnabled end,
                Recipe = function(self, target)
                    return not target.IsHidden
                        and not target.Technology
                        and (not target.Prototype or not target.Prototype.enabled)
                end,
            },
            Sprite = {
                [true] = "automatic-recipe"
            }

        },
        Impossible = {
            Check = {
                Worker = function(self, target) return target.IsEnabled end,
                Recipe = function(self, target)
                    return not target.IsHidden
                        and not target.Technology
                        and (not target.Prototype or not target.Prototype.enabled)
                end,
            },
            Sprite = {
                [true] = "utility/crafting_machine_recipe_not_unlocked"
            }

        },
        Initial = {
            Check = {
                Worker = function(self, target) return target.IsEnabled end,
                Recipe = function(self, target)
                    return not target.Technology
                        and target.Prototype
                        and target.Prototype.enabled
                end,
            },
            Sprite = {
                [true] = "factorio"
            }

        },
        Enabled = {
            Check = {
                Worker = function(self, target) return target.IsEnabled end,
                Recipe = function(self, target) return target.IsEnabled end,
            },
            Sprite = {
                [false] = "utility/check_mark",
                [true] = "utility/check_mark_white"
            }

        },
        Edge = {
            Check = { Worker = function(self, target) return target.IsEnabled end,
            Recipe = function(self, target) return target.Technology and target.Technology.IsReadyRaw end, },
            Sprite = {
                [false] = "utility/expand_dark",
                [true] = "utility/expand"
            }
        },
        NextGeneration = {
            Check = { Worker = function(self, target) return true end,
                Recipe = function(self, target) return target.Technology and target.Technology.IsNextGenerationRaw end, }
            , Sprite = {
                [false] = "utility/slot_icon_module_black",
                [true] = "utility/slot_icon_module"
            }
        },
        All = {
            Default = true,
            Check = { Worker = function(self, target) return true end
                , Recipe = function(self, target) return true end,
            },
            Sprite = { [true] = "infinity" }
        },
    }

}
return Result
