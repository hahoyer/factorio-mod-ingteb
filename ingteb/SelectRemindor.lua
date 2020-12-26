local gui = require("__flib__.gui")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local SpritorClass = require("ingteb.Spritor")

local SelectRemindor = {}
local Spritor = SpritorClass:new("SelectRemindor")

gui.add_handlers {
    SelectRemindor = {
        Close = {on_gui_click = function(event) SelectRemindor:OnClose(event) end},
        Main = {
            on_gui_location_changed = function(event)
                global.Location.SelectRemindor = event.element.location
            end,
            on_gui_click = function(event) SelectRemindor:OnClose(event) end,
            on_gui_close = function(event) SelectRemindor:OnClose(event) end,
        },
    },
}

function SelectRemindor:OnClose(event)
    local player = game.players[event.player_index]
    player.gui.screen.SelectRemindor.destroy()
    player.opened = SelectRemindor.Parent
end

function SelectRemindor:CreateSelection(target)
    return target:Select(function(object) return Spritor:GetSpriteButton(object) end)
end

function SelectRemindor:GetLinePart(children)
    local count = math.min(6, children:Count())

    if children:Count() > count then
        return {
            type = "scroll-pane",
            direction = "horizontal",
            vertical_scroll_policy = "never",
            style = "ingteb-scroll-6x1",
            children = children,
        }
    end
    return {type = "flow", direction = "horizontal", children = children}
end

function SelectRemindor:new(player, target)
    Spritor = SpritorClass:new("Remindor")
    local result = gui.build(
        player.gui.screen, {
            {
                type = "frame",
                direction = "vertical",
                name = "SelectRemindor",
                save_as = "Main",
                handlers = "SelectRemindor.Main",
                children = {
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {type = "label", caption = "Select:"},
                            {
                                type = "empty-widget",
                                style = "flib_titlebar_drag_handle",
                                save_as = "DragBar",
                            },
                            {
                                type = "sprite",
                                sprite = "utility/close_white",
                                tooltip = "press to close.",
                                handlers = "SelectRemindor.Close",
                            },
                        },
                    },
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {type = "label", caption = "Target: "},
                            {
                                type = "sprite",
                                sprite = target.SpriteName,
                                tooltip = target:GetHelperText("SelectRemindor"),
                            },
                        },
                    },
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {type = "label", caption = "Recipe: "},
                            {type = "sprite", save_as = "Recipe"},
                            {type = "label", caption = "Variants: "},
                            self:GetLinePart(self:CreateSelection(target.Recipes)),
                        },
                    },
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {type = "label", caption = "Worker: "},
                            {type = "sprite", save_as = "Worker"},
                            {type = "label", caption = "Variants: "},
                            self:GetLinePart(self:CreateSelection(target.Workers)),
                        },
                    },
                },
            },
        }
    )

    result.DragBar.drag_target = result.Main

    if global.Location.SelectRemindor then
        result.Main.location = global.Location.SelectRemindor
    else
        result.Main.force_auto_center()
        global.Location.SelectRemindor = result.Main.location
    end

    self.Parent = player.opened
    player.opened = result.Main
    return self
end

return SelectRemindor
