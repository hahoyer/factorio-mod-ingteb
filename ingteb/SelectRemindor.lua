local gui = require("__flib__.gui-beta")
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
        actions = {on_click = {gui = "SelectRemindor", action = "Click"}},
        style = Helper.SpriteStyleFromCode(styleCode),
    }
end

function SelectRemindor:OnTextChanged(global, value) self.Count = tonumber(value) end

function SelectRemindor:OnGuiClick(global, target)
    if target.IsRecipe then
        self.Recipe = target
        if not self:GetBelongingWorkers(self.Recipe):Contains(self.Worker) then
            self.Worker = self:GetBelongingWorkers(self.Recipe):Top(false)
        end
    else
        self.Worker = target
        -- DebugAdapter.print(indent .. "------------------------------------------------------")
        -- DebugAdapter.print(indent .. "SelectRemindor:OnGuiClick worker = {target.CommonKey}")
        local old = AddIndent()
        local recipes = self:GetBelongingRecipes(self.Worker)
        indent = old
        -- DebugAdapter.print(indent .. "------------------------------------------------------")
        if not recipes:Contains(self.Recipe) then self.Recipe = recipes:Top(false) end
    end
    local player = game.players[global.Index]
    self:OnClose(player)
    self:Refresh(global)
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
    -- DebugAdapter.print(indent .. "SelectRemindor:GetBelongingWorkers recipe = {recipe.CommonKey}")
    local old = AddIndent()
    local results = self.Workers:Where(
        function(worker)
            -- DebugAdapter.print(indent .. "worker = {worker.CommonKey}")
            local old = AddIndent()
            local result = worker.RecipeList:Any(
                function(category, name)
                    -- DebugAdapter.print(indent .. "category = {name}")
                    local old = AddIndent()
                    local result = category:Contains(recipe)
                    indent = old
                    -- DebugAdapter.print(indent .. "result = {result}")
                    return result
                end
            )
            indent = old
            -- DebugAdapter.print(indent .. "result = {result}")
            return result
        end
    )
    indent = old
    -- DebugAdapter.print(indent .. "results = {results}")
    return results
end

function SelectRemindor:GetBelongingRecipes(worker)
    -- DebugAdapter.print(indent .. "SelectRemindor:GetBelongingRecipes worker = {worker.CommonKey}")
    local old = AddIndent()
    local results = self.Recipes:Where(
        function(recipe)
            -- DebugAdapter.print(indent .. "recipe = {recipe.CommonKey}")
            local old = AddIndent()
            local workers = self:GetBelongingWorkers(recipe)
            local result = workers:Contains(worker)
            indent = old
            -- DebugAdapter.print(indent .. "result = {result}")
            return result
        end
    )
    indent = old
    -- DebugAdapter.print(indent .. "results = {results}")
    return results
end

---@param global table Global data for player
---@param location table GuiLocation (optional)
function SelectRemindor:Refresh(global, location)
    assert(release or self.Recipe)
    assert(release or self.Worker)

    local player = game.players[global.Index]
    local result = gui.build(player.gui.screen, {self:GetGui()})

    result.DragBar.drag_target = result.Main

    if location then
        result.Main.location = location
    elseif global.Location.SelectRemindor then
        result.Main.location = global.Location.SelectRemindor
    else
        result.Main.force_auto_center()
        global.Location.SelectRemindor = result.Main.location
    end

    self.Parent = player.opened
    global.IsPopup = true
    player.opened = result.Main
    global.IsPopup = nil
end

function SelectRemindor:GetSelection()
    return {
        Target = self.Target:CreateStack{value = self.Count},
        Worker = self.Worker,
        Recipe = self.Recipe,
        GetCommonKey = function(self)
            return self.Target.Goods.Name .. ":" .. self.Worker.Name .. ":" .. self.Recipe.Name
        end,
    }
end

---@param global table Global data for player
---@param action table Common
---@param location table GuiLocation (optional)
---@return table
function SelectRemindor:new(global, action, location)
    assert(release or not self.Target)
    self.Target = action.ReminderTask
    self.Count = action.Count
    self.Recipes = self.Target.Recipes
    self.Workers = self.Target.Workers
    self.Recipe = self.Recipes[1]
    self.Worker = self:GetBelongingWorkers(self.Recipe):Top()

    self:Refresh(global, location)
    return self
end

function SelectRemindor:GetWorkersAndRecipes()
    local result = Array:new{}

    if self.Workers:Count() > 1 then
        result:Append{
            type = "flow",
            direction = "horizontal",
            children = {
                {type = "label", caption = "Worker: "},
                {type = "sprite", sprite = self.Worker.SpriteName, ref = {"Worker"}},
                {type = "label", caption = "Variants: "},
                self:GetLinePart(self:CreateSelection(self.Workers)),
            },
        }
    end

    if self.Recipes:Count() > 1 then
        result:Append{
            type = "flow",
            direction = "horizontal",
            children = {
                {type = "label", caption = "Recipe: "},
                {type = "sprite", sprite = self.Recipe.SpriteName, ref = {"Recipe"}},
                {type = "label", caption = "Variants: "},
                self:GetLinePart(self:CreateSelection(self.Recipes)),
            },
        }
    end

    return result
end

function SelectRemindor:GetGui()
    return {
        type = "frame",
        direction = "vertical",
        name = "SelectRemindor",
        ref = {"Main"},
        actions = {
            on_location_changed = {gui = "SelectRemindor", action = "Moved"},
            on_closed = {gui = "SelectRemindor", action = "Closed"},
        },
        children = {
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {type = "label", caption = "Select:"},
                    {type = "empty-widget", style = "flib_titlebar_drag_handle", ref = {"DragBar"}},
                    {
                        type = "sprite-button",
                        sprite = "utility/check_mark_white",
                        actions = {on_click = {gui = "SelectRemindor", action = "Enter"}},
                        style = "frame_action_button",
                    },
                    {
                        type = "sprite-button",
                        sprite = "utility/close_white",
                        tooltip = "press to close.",
                        actions = {on_click = {gui = "SelectRemindor", action = "Closed"}},
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
                    {
                        type = "textfield",
                        numeric = true,
                        text = self.Count,
                        style_mods = {maximal_width = 100},
                        actions = {
                            on_text_changed = {gui = "SelectRemindor", action = "CountChanged"},
                        },
                    },
                },
            },
            {type = "flow", direction = "vertical", children = self:GetWorkersAndRecipes()},
        },
    }
end

return SelectRemindor
