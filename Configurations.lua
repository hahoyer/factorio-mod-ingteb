local Table = require "core.Table"
local Array = Table.Array
local Dictionary = Table.Dictionary

local Result = {
    Presentator = {
        Filter = Dictionary:new {
            Selectable = {
                Default = true,
                Check = {
                    Worker = function(self, target) return true end,
                    Recipe = function(self, target) return target.IsSelectable end,
                },
                Sprite = {
                    [true] = "factorio"
                }

            },
            Automatic = {
                Default = true,
                Check = {
                    Worker = function(self, target) return true end,
                    Recipe = function(self, target) return target.IsAutomatic end,
                },
                Sprite = {
                    [true] = "automatic-recipe"
                }

            },
            Enabled = {
                Root = true,
                Default = true,
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
                Root = true,
                Default = true,
                Check = { Worker = function(self, target) return target.IsEnabled end,
                    Recipe = function(self, target) return target.Technology and target.Technology.IsReadyRaw end, },
                Sprite = {
                    [false] = "utility/expand_dark",
                    [true] = "utility/expand"
                }
            },
            NextGeneration = {
                Root = true,
                Default = true,
                Check = { Worker = function(self, target) return true end,
                    Recipe = function(self, target) return target.Technology and target.Technology.IsNextGenerationRaw end, }
                , Sprite = {
                    [false] = "utility/slot_icon_module_black",
                    [true] = "utility/slot_icon_module"
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
        },
        FilterRule = function(results)
            return (results.Selectable or results.Automatic)
                and
                (results.Enabled or results.Edge or results.NextGeneration)
        end
    },

    Remindor = { AutoResearch = {
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
    },

    SelectRemindor = {
        SpriteStyle = {
            Current = "ingteb-light-button",
            Enabled = "slot_button",
            Edge = "yellow_slot_button",
            NextGeneration = "red_slot_button"
        }
    },

    Database = {
        ResourceTypes = {
            resource = true,
            tree = true,
            fish = true,
            ["simple-entity"] = true,
        },
        BackLinkMetaData = {
            LuaEntityPrototype = {
                group = {},
                subgroup = {},
                type = { Type = "entityType" },
                mineable_properties = { Properties = { "products" } },
                fluidbox_prototypes = { GetName = function(value) return value.filter and value.filter.name or "" end },
                items_to_place_this = { Type = "item" },
                fast_replaceable_group = {},
                next_upgrade = {},
                related_underground_belt = {},
                burner_prototype = { Properties = { "fuel_categories" }, Type = "fuel_category", IsList = true },
                resource_categories = { Type = "resource_category", IsList = true },
                crafting_categories = { Type = "recipe_category", IsList = true },
                fluid = {},
                fixed_recipe = { Type = "recipe" },
                lab_inputs = { Type = "item" },
                rocket_entity_prototype = {},
                resource_category = {},
                attack_parameters = { Properties = { "ammo_categories" }, Type = "ammo_category" },
            },
            LuaFluidPrototype = {
                group = {},
                subgroup = {},
            },
            LuaItemPrototype = {
                group = {},
                subgroup = {},
                burnt_result = {},
                fuel_category = {},
                place_result = {},
                rocket_launch_products = {},
                module_effects = { Type = "module_effect", IsList = true },
                category = { Type = "module_category" },
            },
            LuaRecipePrototype = {
                category = {},
                group = {},
                ingredients = {},
                main_product = {},
                products = {},
                subgroup = {},
            },
            LuaTechnologyPrototype = {
                effects = { GetValue = "GetTechnologyEffect" },
                prerequisites = { IsList = true },
                research_unit_ingredients = {},
            },
        }
    }

}

return Result
