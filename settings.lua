local Constants = require("Constants")

data:extend{
    {
        type = "int-setting",
        name = "ingteb_column-tab-threshold",
        setting_type = "runtime-per-user",
        default_value = 3,
        minimum_value = 0,
        order = "a",
    },
    {
        type = "int-setting",
        name = "ingteb_group-tab-threshold",
        setting_type = "runtime-per-user",
        default_value = 10,
        minimum_value = 0,
        order = "b",
    },
    {
        type = "int-setting",
        name = "ingteb_subgroup-tab-threshold",
        setting_type = "runtime-per-user",
        default_value = 10,
        minimum_value = 0,
        order = "c",
    },
    {
        type = "bool-setting",
        name = "ingteb_reminder-task-autoresearch",
        setting_type = "runtime-per-user",
		default_value = false,
        order = "d1",
    },
    {
        type = "string-setting",
        name = "ingteb_reminder-task-autocrafting",
        setting_type = "runtime-per-user",
        allowed_values = {
            "off",
            "1",
            "5",
            "all",
		},
		default_value = "off",
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
