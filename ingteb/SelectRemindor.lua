local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local RemindorSettings = require "ingteb.RemindorSettings"
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")

local Class = class:new(
    "SelectRemindor", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
        Database = {get = function(self) return self.Parent.Database end},
        LocalSettings = {get = function(self) return self.Global.SelectRemindor.Settings end},
        DefaultSettings = {get = function(self) return self.Parent.Modules.Remindor end},
        Memento = {
            get = function(self)
                return {
                    Target = self.Target.CommonKey,
                    Count = self.Count,
                    Worker = self.Worker.CommonKey,
                    Recipe = self.Recipe.CommonKey,
                    CommonKey = self.Target.CommonKey .. ":" .. self.Worker.Name .. ":"
                        .. self.Recipe.Name,
                    Settings = self.Global.SelectRemindor.Settings,
                }
            end,
        },
        MainGui = {
            get = function(self)
                return self.Player.gui.screen[Constants.ModName .. "." .. self.class.name]
            end,
        },
    }

)

function Class:new(parent)
    local self = self:adopt{Parent = parent}
    self.Settings = RemindorSettings:new(self, {ButtonSize = 28})
    return self
end

function Class:Reopen()
    self:DestroyGui()
    self:CreateGui()
end

function Class:EnsureGlobals()
    if not self.Global.SelectRemindor then self.Global.SelectRemindor = {} end
    if not self.Global.SelectRemindor.Settings then self.Global.SelectRemindor.Settings = {} end
end

function Class:Open(action, location)
    if action then self:Setup(action) end
    if location then self.Global.Location.SelectRemindor = location end
    self:EnsureGlobals()
    self:CreateGui()
end

function Class:Setup(action)
    self.Target = action.RemindorTask
    self.Count = action.Count or 1
    self.Recipes = self.Target.AllRecipes
    self.Workers = self.Target.Workers
    self.Recipe = self.Recipes[1]
    self.Worker = self:GetBelongingWorkers(self.Recipe):Top()
end

function Class:CreateGui()
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
    )
end

function Class:Close()
    self:DestroyGui()
    self:Clear()
end

function Class:OnSettingsChanged(event)
    -- dassert()   
end

function Class:DestroyGui()
    if not self.MainGui then return end
    self.MainGui.destroy()
    local parentScreen = self.ParentScreen
    if parentScreen and parentScreen.valid and parentScreen.object_name == "LuaGuiElement" then
        parentScreen.ignored_by_interaction = nil
        self.Player.opened = parentScreen
    end
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
    self:Close()
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
        actions = {on_click = {module = self.class.name, action = "Click", key = target.CommonKey}},
        style = Helper.SpriteStyleFromCode(styleCode),
        tooltip = target:GetHelperText(self.class.name),
    }
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    if message.action == "Closed" then
        self:Close()
    elseif message.action == "Click" then
        if message.control == "Settings" then
            self.Settings:OnClick(event)
            self:Reopen()
        else
            local commonKey = message.key or event.element.name
            if commonKey then
                self:OnGuiClick(self.Database:GetProxyFromCommonKey(commonKey))
            end
        end
    elseif message.action == "CountChanged" then
        self:OnTextChanged(event.element.text)
    elseif message.action == "Enter" then
        local selection = self.Memento
        self:Close()
        self.Parent:AddRemindor(selection)
    else
        dassert()
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
        local recipes = self:GetBelongingRecipes(self.Worker)
        if not recipes:Contains(self.Recipe) then self.Recipe = recipes:Top(false) end
    end
    self:Reopen()
end

function Class:OnTextChanged(value) self.Count = tonumber(value) end

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
    local results = self.Workers:Where(
        function(worker)
            local result = worker.Recipes:Any(
                function(category, name)
                    local result = category:Contains(recipe)
                    return result
                end
            )
            return result
        end
    )
    return results
end

function Class:GetBelongingRecipes(worker)
    local results = self.Recipes:Where(
        function(recipe)
            local workers = self:GetBelongingWorkers(recipe)
            local result = workers:Contains(worker)
            return result
        end
    )
    return results
end

function Class:GetTargetGui()
    return {
        type = "flow",
        direction = "horizontal",
        children = {
            {type = "label", caption = {"ingteb-utility.select-target"}},
            {
                type = "sprite",
                sprite = self.Target.SpriteName,
                tooltip = self.Target:GetHelperText(self.class.name),
            },
            {
                type = "textfield",
                numeric = true,
                allow_negative = true,
                allow_decimal = true,
                text = self.Count,
                style_mods = {maximal_width = 60, height = 26},
                actions = {on_text_changed = {module = self.class.name, action = "CountChanged"}},
            },
            {
                type = "flow",
                direction = "horizontal",
                style_mods = {horizontal_align = "right", horizontally_stretchable = "on"},
                children = {self.Settings:GetGui()},
            },
        },
    }
end

function Class:GetWorkersGui()
    return {
        type = "flow",
        direction = "horizontal",
        children = {
            {type = "label", caption = {"ingteb-utility.select-worker"}},
            {
                type = "sprite",
                sprite = self.Worker.SpriteName,
                ref = {"Worker"},
                tooltip = self.Worker:GetHelperText(self.class.name),
            },
            {type = "label", caption = {"ingteb-utility.select-variants"}},
            self:GetLinePart(self:CreateSelection(self.Workers)),
        },
    }
end

function Class:GetRecipesGui()
    return {
        type = "flow",
        direction = "horizontal",
        children = {
            {type = "label", caption = {"ingteb-utility.select-recipe"}},
            {
                type = "sprite",
                sprite = self.Recipe.SpriteName,
                ref = {"Recipe"},
                tooltip = self.Worker:GetHelperText(self.class.name),
            },
            {type = "label", caption = {"ingteb-utility.select-variants"}},
            self:GetLinePart(self:CreateSelection(self.Recipes)),
        },
    }
end

function Class:GetSettingsGui() return self.Settings:GetGui() end

function Class:GetGui()
    local children = Array:new{
        {self:GetTargetGui()},
        self.Workers:Count() > 1 and {self:GetWorkersGui()} or {},
        self.Recipes:Count() > 1 and {self:GetRecipesGui()} or {},
    }
    return {type = "flow", direction = "vertical", children = children:ConcatMany()}
end

return Class
