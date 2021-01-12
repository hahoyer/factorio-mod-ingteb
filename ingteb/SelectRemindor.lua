local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")

local Class = class:new(
    "SelectRemindor", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
    }
)

function Class:new(parent, action, location)
    local self = Class:adopt{Parent = parent}
    self.Target = action.ReminderTask
    self.Count = action.Count
    self.Recipes = self.Target.Recipes
    self.Workers = self.Target.Workers
    self.Recipe = self.Recipes[1]
    self.Worker = self:GetBelongingWorkers(self.Recipe):Top()

    self.Current = Helper.CreatePopupFrameWithContent(
        self, self:GetGui(), {"ingteb-utility.select-reminder"}, {
            buttons = {
                {
                    type = "sprite-button",
                    sprite = "utility/check_mark_white",
                    actions = {on_click = {module = self.class.name, action = "Enter"}},
                    style = "frame_action_button",
                },
            },
        }
    ).Main

    return self
end

function Class:Close()
    self.Current.destroy()
    self.ParentScreen.ignored_by_interaction = nil
    self.Player.opened = self.ParentScreen
    self.Target = nil
end

function Class:GetWorkerSpriteStyle(target)
    if target == self.Worker then return true end
    if not self:GetBelongingWorkers(self.Recipe):Contains(target) then return false end
end

function Class:GetRecipeSpriteStyle(target)
    if target == self.Recipe then return true end
    if not self:GetBelongingRecipes(self.Worker):Contains(target) then return false end
end

function Class:GetSpriteButton(target)
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
        actions = {on_click = {module = self.class.name, action = "Click"}},
        style = Helper.SpriteStyleFromCode(styleCode),
    }
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    if message.action == "Closed" then
        self:Close()
    elseif message.action == "Click" then
        local commonKey = event.element.name
        self:Close()
        self.Parent:PresentTargetByCommonKey(commonKey)
    else
        assert(release)
    end
end

function Class:OnTextChanged(global, value)
    assert(release)
    self.Count = tonumber(value)
end

function Class:OnGuiClick(global, target)
    assert(release)
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

function Class:GetSelection()
    assert(release)
    return {
        Target = self.Target:CreateStack{value = self.Count},
        Worker = self.Worker,
        Recipe = self.Recipe,
        GetCommonKey = function(self)
            return self.Target.Goods.Name .. ":" .. self.Worker.Name .. ":" .. self.Recipe.Name
        end,
    }
end

function Class:CreateSelection(target)
    return target:Select(function(object) return self:GetSpriteButton(object) end)
end

function Class:GetLinePart(children)
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

function Class:GetBelongingWorkers(recipe)
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

function Class:GetBelongingRecipes(worker)
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

function Class:GetWorkersAndRecipes()
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

function Class:GetGui()
    return {
        type = "flow",
        direction = "vertical",
        children = {
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
                            on_text_changed = {module = self.class.name, action = "CountChanged"},
                        },
                    },
                },
            },
            {type = "flow", direction = "vertical", children = self:GetWorkersAndRecipes()},
        },
    }
end

return Class
