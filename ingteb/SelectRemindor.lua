local gui = require("__flib__.gui")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")

local SelectRemindor = class:new("SelectRemindor")

function SelectRemindor:OnClose(player)
    player.gui.screen.SelectRemindor.destroy()
    player.opened = SelectRemindor.Parent
end

function SelectRemindor:GetWorkerSpriteStyle(target)
    if target == self.Worker then return true end
    if not self:GetBelongingWorkers(self.Recipe):Contains(target) then return false end
end

function SelectRemindor:GetRecipeSpriteStyle(target)
    if target == self.Recipe then return true end
    if not self:GetBelongingRecipes(self.Worker):Contains(target) then return false end
end

function SelectRemindor:GetSpriteButton(target)

    local styleCode
    if target.IsRecipe then
        styleCode = self:GetRecipeSpriteStyle(target)
    else
        styleCode = self:GetWorkerSpriteStyle(target)
    end

    local sprite = target.SpriteName
    if sprite == "fuel-category/chemical" then sprite = "chemical" end

    return {
        type = "sprite-button",
        sprite = sprite,
        name = target.CommonKey,
        handlers = "SelectRemindor.Button",
        style = Helper.SpriteStyleFromCode(styleCode),
    }
end

function SelectRemindor:OnGuiClick(player, target)
    if target.IsRecipe then
        self.Recipe = target
        if not self:GetBelongingWorkers(self.Recipe):Contains(self.Worker) then
            self.Worker = self:GetBelongingWorkers(self.Recipe):Top(false)
        end
    else
        self.Worker = target
        if not self:GetBelongingRecipes(self.Worker):Contains(self.Recipe) then
            self.Recipe = self:GetBelongingRecipes(self.Worker):Top(false)
        end
    end
    self:OnClose(player)
    self:Refresh(player)
end

function SelectRemindor:CreateSelection(target)
    return target:Select(function(object) return self:GetSpriteButton(object) end)
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

function SelectRemindor:GetBelongingWorkers(recipe)
    local result = self.Workers:Where(
        function(worker)
            return worker.RecipeList:Any(
                function(category) return category:Contains(recipe) end
            )
        end
    )
    return result
end

function SelectRemindor:GetBelongingRecipes(worker)
    local result = self.Recipes:Where(
        function(recipe) return self:GetBelongingWorkers(recipe):Contains(worker) end
    )
    return result
end

function SelectRemindor:Refresh(player)
    assert(release or self.Recipe)
    assert(release or self.Worker)

    local result = gui.build(player.gui.screen, {self:GetGui()})

    result.DragBar.drag_target = result.Main

    if global.Location.SelectRemindor then
        result.Main.location = global.Location.SelectRemindor
    else
        result.Main.force_auto_center()
        global.Location.SelectRemindor = result.Main.location
    end

    self.Parent = player.opened
    player.opened = result.Main
end

function SelectRemindor:GetSelection()
    return {
        Target = self.Target,
        Worker = self.Worker,
        Recipe = self.Recipe,
        GetCommonKey = function(self)
            return self.Target.Name .. ":" .. self.Worker.Name .. ":" .. self.Recipe.Name
        end,
    }
end

function SelectRemindor:new(player, target)
    assert(release or not self.Target)
    self.Target = target
    self.Recipes = self.Target.Recipes
    self.Workers = self.Target.Workers
    self.Recipe = self.Recipes[1]
    self.Worker = self:GetBelongingWorkers(self.Recipe):Top()

    self:Refresh(player)
    return self
end

function SelectRemindor:GetGui()
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
                        sprite = "utility/check_mark_white",
                        handlers = "SelectRemindor.Enter",
                        style = "frame_action_button",
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
                        sprite = self.Target.SpriteName,
                        tooltip = self.Target:GetHelperText("SelectRemindor"),
                    },
                },
            },
            {
                type = "condition",
                condition = self.Workers:Count() > 1,
                children = {
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {type = "label", caption = "Worker: "},
                            {type = "sprite", sprite = self.Worker.SpriteName, save_as = "Worker"},
                            {type = "label", caption = "Variants: "},
                            self:GetLinePart(self:CreateSelection(self.Workers)),
                        },
                    },
                },
            },
            {
                type = "condition",
                condition = self.Recipes:Count() > 1,
                children = {
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {type = "label", caption = "Recipe: "},
                            {type = "sprite", sprite = self.Recipe.SpriteName, save_as = "Recipe"},
                            {type = "label", caption = "Variants: "},
                            self:GetLinePart(self:CreateSelection(self.Recipes)),
                        },
                    },
                },
            },
        },
    }
end

return SelectRemindor
