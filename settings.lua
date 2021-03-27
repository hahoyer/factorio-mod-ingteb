local Constants = require("Constants")

data:extend{
    {
        type = "string-setting",
        name = "ingteb_production-timeunit",
        setting_type = "runtime-per-user",
        default_value = "0:01",
        order = "b",
    },
    {
        type = "int-setting",
        name = "ingteb_column-tab-threshold",
        setting_type = "runtime-per-user",
        default_value = 3,
        minimum_value = 0,
        order = "a1",
    },
    {
        type = "int-setting",
        name = "ingteb_group-tab-threshold",
        setting_type = "runtime-per-user",
        default_value = 10,
        minimum_value = 0,
        order = "a2",
    },
    {
        type = "int-setting",
        name = "ingteb_subgroup-tab-threshold",
        setting_type = "runtime-per-user",
        default_value = 10,
        minimum_value = 0,
        order = "a3",
    },
    {
        type = "string-setting",
        name = "ingteb_reminder-task-autoresearch",
        setting_type = "runtime-per-user",
		default_value = "1",
        order = "d1",
        allowed_values = {
            "off",
            "1",
            "all",
		},
    },
    {
        type = "bool-setting",
        name = "ingteb_reminder-task-autocrafting",
        setting_type = "runtime-per-user",
		default_value = false,
        order = "d2",
    },
    {
        type = "bool-setting",
        name = "ingteb_reminder-task-remove-when-fulfilled",
        setting_type = "runtime-per-user",
		default_value = false,
        order = "d3",
    },
}
