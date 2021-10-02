local data_util = require('__flib__.data-util')
local Constants = require("Constants")

local big_size = 64
local small_size = 32
local tiny_size = 24
local frame_action_icons = Constants.GraphicsPath .. "frame-action-icons.png"

data:extend(
    {
        {
            type = "custom-input",
            name = Constants.Key.Main,
            key_sequence = "H",
            include_selected_prototype = true,
        },
        {type = "custom-input", name = Constants.Key.Back, key_sequence = "mouse-button-4"},
        {type = "custom-input", name = Constants.Key.Fore, key_sequence = "mouse-button-5"},

        {
            type = "sprite",
            name = "factorio",
            filename = "__core__/graphics/factorio-icon.png",
            size = 64,
            scale = 0.5,
        },
        {
            type = "sprite",
            name = "ingteb",
            filename = "__" .. Constants.ModName .. "__/thumbnail.png",
            size = 64,
            scale = 0.5,
        },
        {
            type = "sprite",
            name = "chemical",
            filename = Constants.GraphicsPath .. "chemical.png",
            size = 64,
            scale = 0.5,
        },
        {
            type = "sprite",
            name = "effects",
            filename = Constants.GraphicsPath .. "effects.png",
            size = 32,
            scale = 0.5,
        },
        {
            type = "sprite",
            name = "hide-this-column",
            filename = "__core__/graphics/cancel.png",
            size = 64,
            scale = 0.5,
        },
        {
            type = "sprite",
            name = "items-per-timeunit",
            filename = Constants.GraphicsPath .. "items-per-timeunit.png",
            size = 34,
        },
        {
            type = "sprite",
            name = "setting-is-off",
            filename = "__core__/graphics/no-recipe.png",
            width = 101,
            height = 101,
            scale = 0.6,
        },

        data_util.build_sprite("ingteb_settings_black", {0, 96}, frame_action_icons, 32),
        data_util.build_sprite("ingteb_settings_white", {32, 96}, frame_action_icons, 32),

        -- Icons copied from game core

        {
            type = "sprite",
            name = "go_to_arrow",
            filename = Constants.GraphicsPath .. "goto-icon.png",
            priority = "medium",
            width = 32,
            height = 32,
            flags = {"icon"},
        },

        {
            type = "sprite",
            name = "close_white",

            filename = Constants.GraphicsPath .. "close-white.png",
            priority = "extra-high-no-scale",
            size = 32,
            scale = 0.5,
            flags = {"gui-icon"},
        },
        {
            type = "sprite",
            name = "close_black",
            filename = Constants.GraphicsPath .. "close-black.png",
            priority = "extra-high-no-scale",
            size = 32,
            scale = 0.5,
            flags = {"gui-icon"},
        },

        {
            type = "sprite",
            name = "search_black",
            filename = Constants.GraphicsPath .. "search-black.png",
            priority = "extra-high-no-scale",
            size = 32,
            scale = 0.5,
            flags = {"gui-icon"},
        },
        {
            type = "sprite",
            name = "search_white",
            filename = Constants.GraphicsPath .. "search-white.png",
            priority = "extra-high-no-scale",
            size = 32,
            scale = 0.5,
            flags = {"gui-icon"},
        },

        {
            type = "sprite",
            name = "slot_icon_robot_material",
            filename = Constants.GraphicsPath .. "slot-robot-material-white.png",
            priority = "medium",
            width = 64,
            height = 64,
            mipmap_count = 3,
            scale = 0.5,
            flags = {"gui-icon"},
        },
        {
            type = "sprite",
            name = "slot_icon_robot_material_black",
            filename = Constants.GraphicsPath .. "slot-robot-material-black.png",
            priority = "medium",
            width = 64,
            height = 64,
            mipmap_count = 3,
            scale = 0.5,
            flags = {"gui-icon"},
        },
        {
            type = "sprite",
            name = "technology_black",
            filename = Constants.GraphicsPath .. "technology-black.png",
            size = 64,
            mipmap_count = 2,
            scale = 0.5,
            flags = {"gui-icon"},
        },
        {
            type = "sprite",
            name = "technology_white",
            filename = Constants.GraphicsPath .. "technology-white.png",
            size = 64,
            mipmap_count = 2,
            scale = 0.5,
            flags = {"gui-icon"},
        },
        {
            type = "sprite",
            name = "trash",
            filename = Constants.GraphicsPath .. "trash.png",
            priority = "extra-high-no-scale",
            size = 32,
            flags = {"gui-icon"},
            mipmap_count = 2,
            scale = 0.5,
        },

        {
            type = "sprite",
            name = "trash_white",
            filename = Constants.GraphicsPath .. "trash-white.png",
            priority = "extra-high-no-scale",
            size = 32,
            scale = 0.5,
            mipmap_count = 2,
            flags = {"gui-icon"},
        },
    }
)

data.raw["utility-sprites"].default.factorio = {
    filename = "__core__/graphics/factorio.icon",
    priority = "medium",
    size = 32,
    flags = {"icon"},
}

data.raw["utility-sprites"].default.settings = data_util.build_sprite {
    filename = "__core__/graphics/factorio.icon",
    priority = "medium",
    size = 32,
    flags = {"icon"},
}

data.raw["gui-style"].default["ingteb-flow-centered"] = {
    type = "horizontal_flow_style",
    horizontally_stretchable = "on",
    horizontal_align = "center",
}

data.raw["gui-style"].default["ingteb-scroll-6x1"] = {
    type = "scroll_pane_style", --
    parent = "scroll_pane",
    width = 43 * 6,
}

data.raw["gui-style"].default["ingteb-main-frame"] = {
    type = "frame_style", --
    scalable = true,
}

data.raw["gui-style"].default["ingteb-flow-right"] = { --
    type = "horizontal_flow_style", --
    horizontally_stretchable = "on",
    horizontal_align = "right",
}

data.raw["gui-style"].default["ingteb-flow-fill"] = { --
    type = "vertical_flow_style", --
    horizontally_stretchable = "on",
}

local default_glow_color = {225, 177, 106, 255}
local default_dirt_color = {15, 7, 3, 100}
local red_color = {1, 0, 0, 100}

local function offset_by_2_rounded_corners_glow(tint_value)
    return {
        position = {240, 736},
        corner_size = 16,
        tint = tint_value,
        top_outer_border_shift = 4,
        bottom_outer_border_shift = -4,
        left_outer_border_shift = 4,
        right_outer_border_shift = -4,
        draw_type = "outer",
    }
end

local function sprite17(x, y) return {border = 4, position = {x * 17, y * 17}, size = 16} end
data.raw["gui-style"].default["ingteb-light-button"] = {
    type = "button_style",
    parent = "button",
    draw_shadow_under_picture = true,
    size = 40,
    padding = 0,
    default_graphical_set = {
        base = sprite17(0, 1),
        -- shadow = offset_by_2_rounded_corners_glow(default_dirt_color)
    },
    hovered_graphical_set = {
        base = sprite17(2, 1),
        -- shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
        -- glow = offset_by_2_rounded_corners_glow(default_glow_color)
    },
    clicked_graphical_set = {
        base = sprite17(3, 1),
        shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    selected_graphical_set = {
        base = sprite17(2, 1),
        shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    selected_hovered_graphical_set = {
        base = sprite17(2, 1),
        shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
        glow = offset_by_2_rounded_corners_glow(default_glow_color),
    },
    selected_clicked_graphical_set = {
        base = sprite17(3, 1),
        shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    pie_progress_color = {0.98, 0.66, 0.22, 0.5},
}

data.raw["gui-style"].default["ingteb-un-button"] = {type = "image_style", size = 40}
data.raw["gui-style"].default["ingteb-tab"] = {type = "tab_style", size = 40}

data:extend{{type = "font", name = "ingteb-font18", from = "default", size = 18}}

data:extend{{type = "font", name = "ingteb-font24", from = "default", size = 24}}

data:extend{{type = "font", name = "ingteb-font32", from = "default", size = 32}}

data.raw["gui-style"].default["ingteb-big-tab"] = {type = "tab_style", font = "ingteb-font32"}

data.raw["gui-style"].default["ingteb-big-tab-disabled"] = {
    type = "tab_style",
    font = "ingteb-font32",
    default_graphical_set = {base = {position = {208, 17}, corner_size = 8}},
}

data.raw["gui-style"].default["ingteb-medium-tab"] = {
    type = "tab_style",
    font = "ingteb-font18",
    size = 40,
}

data.raw["gui-style"].default["ingteb-big-label"] = {type = "label_style", font = "ingteb-font24"}
