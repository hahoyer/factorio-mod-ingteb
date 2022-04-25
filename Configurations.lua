local Table = require "core.Table"
local Array = Table.Array
local Dictionary = Table.Dictionary

local Result = {
    PresentatorFilter = Dictionary:new {
        Initial = {
            Default = true,
            Check = {
                Worker = function(self, target) return target.IsEnabled end,
                Recipe = function(self, target) return target.IsInitial end,
            },
            Sprite = {
                [true] = "factorio"
            }

        },
        Automatic = {
            Default = true,
            Check = {
                Worker = function(self, target) return target.IsEnabled end,
                Recipe = function(self, target) return target.IsHidden end,
            },
            Sprite = {
                [true] = "automatic-recipe"
            }

        },
        Enabled = {
            Default = true,
            Check = {
                Worker = function(self, target) return target.IsEnabled end,
                Recipe = function(self, target) return 
                    target.IsEnabled 
                    and not target.IsInitial
                    and not target.IsHidden
                end,
            },
            Sprite = {
                [false] = "utility/check_mark",
                [true] = "utility/check_mark_white"
            }

        },
        Edge = {
            Default = true,
            Check = { Worker = function(self, target) return target.IsEnabled end,
                Recipe = function(self, target) return target.Technology and target.Technology.IsReadyRaw end, },
            Sprite = {
                [false] = "utility/expand_dark",
                [true] = "utility/expand"
            }
        },
        NextGeneration = {
            Default = true,
            Check = { Worker = function(self, target) return true end,
                Recipe = function(self, target) return target.Technology and target.Technology.IsNextGenerationRaw end, }
            , Sprite = {
                [false] = "utility/slot_icon_module_black",
                [true] = "utility/slot_icon_module"
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
        -- All = {
        --     Default = true,
        --     Check = { Worker = function(self, target) return true end
        --         , Recipe = function(self, target) return true end,
        --     },
        --     Sprite = { [true] = "infinity" },
        -- },

        -- NextWorkers = {
        --     Check = { Worker = function(self, target) return true end
        --         , Recipe = function(self, target) return false end,
        --     },
        --     Sprite = { [true] = "infinity" },
        -- },
    }

}

Result.Remindor = {
    AutoResearch = {
        Name = "ingteb-utility.select-remindor-autoresearch-help",
        SpriteList = { "technology_black", "technology_white" },
        off = { Next = "1", Name = "string-mod-setting.ingteb_reminder-task-autoresearch-off" },
        ["1"] = { Next = "all", Name = "string-mod-setting.ingteb_reminder-task-autoresearch-1" },
        all = { Next = "off", Name = "string-mod-setting.ingteb_reminder-task-autoresearch-all" },
    },
    AutoCrafting = {
        Name = "ingteb-utility.select-remindor-autocrafting-help",
        SpriteList = { "slot_icon_robot_material_black", "slot_icon_robot_material" },
        [true] = { Next = false, Name = "ingteb-utility.settings-switch-on" },
        [false] = { Next = true, Name = "ingteb-utility.settings-switch-off" },
    },
    RemoveTaskWhenFulfilled = {
        Name = "ingteb-utility.select-remindor-remove-when-fulfilled-help",
        SpriteList = { "trash", "trash_white" },
        [true] = { Next = false, Name = "ingteb-utility.settings-switch-on" },
        [false] = { Next = true, Name = "ingteb-utility.settings-switch-off" },
    },
}

return Result
