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
        Database = {get = function(self) return self.Parent.Database end},
    }
)

function Class:new(parent) return self:adopt{Parent = parent} end

function Class:Reopen()
    self:DestroyGui()
    self:CreateGui()
end

function Class:Open(action, location)
    if action then self:Setup(action) end
    if location then self.Global.Location.SelectRemindor = location end
    self:CreateGui()
end

function Class:Setup(action)
    self.Target = action.RemindorTask
    self.Count = action.Count or 1
    self.Recipes = self.Target.Recipes
    self.Workers = self.Target.Workers
    self.Recipe = self.Recipes[1]
    self.Worker = self:GetBelongingWorkers(self.Recipe):Top()
end

function Class:CreateGui()
    self.Current = --
    Helper.CreatePopupFrameWithContent(
        self, self:GetGui(), --
        {"ingteb-utility.select-reminder"}, --
        {
            buttons = {
                {
                    type = "sprite-button",
                    sprite = "utility/check_mark_white",
                    actions = {on_click = {module = self.class.name, action = "Enter"}},
                    style = "frame_action_button",
                },
            },
        }
    ). --
    Main
end

function Class:Close()
    self:DestroyGui()
    self:Clear()
end

function Class:OnSettingsChanged(event)
    -- assert(release)   
end

function Class:DestroyGui()
    self.Current.destroy()
    if not self.ParentScreen then return end
    self.ParentScreen.ignored_by_interaction = nil
    self.Player.opened = self.ParentScreen
end

function Class:Clear()
    self.Target = nil
    self.Recipe = nil
    self.Recipes = nil
    self.Worker = nil
    self.Workers = nil
end

function Class:RestoreFromSave(parent)
    self.Parent = parent
    local current = self.Player.gui.screen[self.class.name]
    if current then current.destroy() end
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
        self:OnGuiClick(self.Database:GetProxyFromCommonKey(commonKey))
    elseif message.action == "CountChanged" then
        self:OnTextChanged(event.element.text)
    elseif message.action == "Enter" then
        local selection = self:GetSelection()
        self:Close()
        self.Parent:AddRemindor(selection)
    else
        assert(release)
    end
end

function Class:OnGuiClick(target)
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
    self:Reopen()
end

function Class:OnTextChanged(value) self.Count = tonumber(value) end

function Class:GetSelection()
    return {
        Target = self.Target.CommonKey,
        Count = self.Count,
        Worker = self.Worker.CommonKey,
        Recipe = self.Recipe.CommonKey,
        CommonKey = self.Target.CommonKey .. ":" .. self.Worker.Name .. ":" .. self.Recipe.Name,
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
                {type = "label", caption = {"ingteb-utility.select-worker"}},
                {type = "sprite", sprite = self.Worker.SpriteName, ref = {"Worker"}},
                {type = "label", caption = {"ingteb-utility.select-variants"}},
                self:GetLinePart(self:CreateSelection(self.Workers)),
            },
        }
    end

    if self.Recipes:Count() > 1 then
        result:Append{
            type = "flow",
            direction = "horizontal",
            children = {
                {type = "label", caption = {"ingteb-utility.select-recipe"}},
                {type = "sprite", sprite = self.Recipe.SpriteName, ref = {"Recipe"}},
                {type = "label", caption = {"ingteb-utility.select-variants"}},
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
                    {type = "label", caption = {"ingteb-utility.select-target"}},
                    {
                        type = "sprite",
                        sprite = self.Target.SpriteName,
                        tooltip = self.Target:GetHelperText("SelectRemindor"),
                    },
                    {
                        type = "textfield",
                        numeric = true,
                        allow_negative = true,
                        allow_decimal = true,
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
