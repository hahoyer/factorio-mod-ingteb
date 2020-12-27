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

    local result = {type = "flow", direction = "horizontal", children = children}

    if children:Count() <= count then return result end
    return {
        type = "scroll-pane",
        direction = "horizontal",
        vertical_scroll_policy = "never",
        style = "ingteb-scroll-6x1",
        children = {result},
    }
end

function SelectRemindor:GetGui(target)
    local recipes = target.Recipes
    local workers = target.Workers
    local recipe = recipes[1]
    local worker = workers:Where(
        function(worker)
            return worker.RecipeList:Where(
                function(category) return category:Contains(recipe) end
            ):Any()
        end
    ):Top()

    return {
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
                        type = "sprite-button",
                        sprite = "utility/close_white",
                        tooltip = "press to close.",
                        handlers = "SelectRemindor.Close",
                        style = "frame_action_button",
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
                type = "condition",
                condition = workers:Count() > 1,
                children = {
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {type = "label", caption = "Worker: "},
                            {type = "sprite", sprite = worker.SpriteName, save_as = "Worker"},
                            {type = "label", caption = "Variants: "},
                            self:GetLinePart(self:CreateSelection(workers)),
                        },
                    },
                },
            },
            {
                type = "condition",
                condition = recipes:Count() > 1,
                children = {
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {type = "label", caption = "Recipe: "},
                            {type = "sprite", sprite = recipe.SpriteName, save_as = "Recipe"},
                            {type = "label", caption = "Variants: "},
                            self:GetLinePart(self:CreateSelection(recipes)),
                        },
                    },
                },
            },
        },
    }
end

function SelectRemindor:new(player, target)
    Spritor = SpritorClass:new("SelectRemindor")
    local result = gui.build(player.gui.screen, {self:GetGui(target)})

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
