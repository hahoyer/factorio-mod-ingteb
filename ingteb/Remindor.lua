local mod_gui = require("mod-gui")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Gui = require "core.gui"
local RemindorTask = require "ingteb.remindortask"
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local SpritorClass = require("ingteb.Spritor")
local RequiredThings = require("ingteb.RequiredThings")
local Item = require("ingteb.Item")
local Task = require("ingteb.RemindorTask")
local Settings = require("ingteb.RemindorSettings")

local Class = class:new(
    "Remindor", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
        Database = {get = function(self) return self.Parent.Database end},
        AutoResearch = {
            get = function(self)
                if self.Settings.AutoResearch ~= nil then
                    return self.Settings.AutoResearch
                end
                return self.ParentData.Settings.AutoResearch
            end,
        },
        AutoCrafting = {
            get = function(self)
                if self.Settings.AutoCrafting ~= nil then
                    return self.Settings.AutoCrafting
                end
                return self.ParentData.Settings.AutoCrafting
            end,
        },
        RemoveTaskWhenFulfilled = {
            get = function(self)
                if self.Settings.RemoveTaskWhenFulfilled ~= nil then
                    return self.Settings.RemoveTaskWhenFulfilled
                end
                return self.ParentData.Settings.RemoveTaskWhenFulfilled
            end,
        },
        Settings = {get = function(self) return self.Global.Remindor.Settings end},
        HelperTextSettings = {
            get = function(self)
                local result = Array:new{}
                if self.AutoResearch then
                    result:Append("\n")
                    result:Append{"ingteb-utility.auto-research"}
                end
                if self.AutoCrafting ~= "off" then
                    result:Append("\n")
                    result:Append{
                        "string-mod-setting.ingteb_reminder-task-autocrafting-" .. self.AutoCrafting,
                    }
                end
                if self.RemoveTaskWhenFulfilled then
                    result:Append("\n")
                    result:Append{"ingteb-utility.remove-when-fulfilled"}
                end
                if result:Any() then
                    result[1] = ""
                    return result
                end
            end,
        },
        ParentData = {
            cache = true,
            get = function(self)
                local playerSettings = settings.get_player_settings(self.Player)
                return {
                    Settings = {
                        AutoResearch = playerSettings["ingteb_reminder-task-autoresearch"].value,
                        AutoCrafting = playerSettings["ingteb_reminder-task-autocrafting"].value,
                        RemoveTaskWhenFulfilled = playerSettings["ingteb_reminder-task-remove-when-fulfilled"]
                            .value,
                    },
                }
            end,
        },
    }
)

function Class:new(parent)
    local self = self:adopt{Parent = parent}
    Spritor = SpritorClass:new(self)
    return self
end

function Class:CloseSettings()
    if not self.CurrentSettings then return end
    self.CurrentSettings.destroy()
    if self.ParentScreen then
        self.ParentScreen.ignored_by_interaction = nil
        self.Player.opened = self.ParentScreen
    end
    self.CurrentSettings = nil
end

function Class:OpenSettings(target)
    self:CloseSettings()
    self.CurrentSettings = Settings.Open(self, target or self)
end

function Class:RefreshSettings(target)
    self.CurrentSettings.destroy()
    if self.ParentScreen then
        self.ParentScreen.ignored_by_interaction = nil
        self.Player.opened = self.ParentScreen
    end
    self.CurrentSettings = Settings.Open(self, target or self)
end

function Class:RestoreFromSave(parent)
    self.Parent = parent
    if not self.Global.Remindor.Settings then self.Global.Remindor.Settings = {} end
    local current = mod_gui.get_frame_flow(self.Player)[self.class.name]
    local list = self.Global.Remindor.List or {}
    self.Global.Remindor.List = Array:new()
    for _, task in ipairs(list) do
        self.Global.Remindor.List:Append(Task:new(RemindorTask.GetSelection(task), self))
    end
    if not current then return end
    current.destroy()
    self:Open()
    local currentSettings = self.Player.gui.screen.RemindorSettings
    if currentSettings then
        local taskIndex = self:GetTaskIndex(currentSettings.children[2].name)
        local target = taskIndex and self.Global.Remindor.List[taskIndex] or self
        currentSettings.destroy()
        self:OpenSettings(target)
    end
end

function Class:Toggle()
    if self.Current then
        self:Close()
        self:CloseSettings()
    else
        self:Open()
    end
end

function Class:Close()
    if not self.Current then return end
    self.Current.destroy()
    self.Current = nil
    Spritor:Close()
end

function Class:Open()
    local result = Helper.CreateLeftSideFrameWithContent(
        self, --
        {type = "flow", ref = {"Tasks"}, direction = "vertical"}, --
        {"ingteb-utility.reminder-tasks"}, --
        {
            buttons = {
                {
                    type = "sprite-button",
                    sprite = "ingteb_settings_white",
                    style = "frame_action_button",
                    actions = {on_click = {module = self.class.name, action = "Settings"}},
                    tooltip = self.HelperTextSettings,
                },
            },
        }
    )
    self.Tasks = result.Tasks
    self.Current = result.Main
    self:Refresh()
end

function Class:Reopen(target)
    if self.CurrentSettings then self:RefreshSettings(target) end
    self:Close()
    self:Open()
end

local isRefreshActive

function Class:Refresh()
    if isRefreshActive then return end
    isRefreshActive = true
    self:EnsureGlobal()
    self.Global.Remindor.Links = Dictionary:new{}
    if self.Tasks then self.Tasks.clear() end
    local data = {}

    if self.Global.Remindor.List then
        self.Global.Remindor.List = self.Global.Remindor.List:Where(
            function(task) return task.IsRelevant end
        )
        self.Global.Remindor.List:Select(
            function(task, index)
                task:CreatePanel(
                    self.Tasks, task.CommonKey, data, index == 1,
                        index == #self.Global.Remindor.List
                )
            end
        )
        self.Global.Remindor.List:Select(function(task) task:AutomaticActions() end)
    else
        self.Global.Remindor.List = Array:new{}
    end
    isRefreshActive = false
end

function Class:EnsureGlobal()
    if not self.Global.Remindor then
        self.Global.Remindor = {List = Array:new{}, Links = Dictionary:new{}}
    end
end

function Class:GetValueOfControl(element)
    if element.type == "checkbox" then
        return element.state
    elseif element.type == "drop-down" then
        return Constants.AutoCraftingVariants[element.selected_index]
    else
        assert(release)
    end
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    local key = message.key or event.element.parent.name
    local taskIndex = message.target == "Task" and self:GetTaskIndex(key) or nil
    assert(release or message.target ~= "Task" or taskIndex)
    local target = taskIndex and self.Global.Remindor.List[taskIndex] or self

    if message.action == "Update" then
        target.Settings[message.control] = self:GetValueOfControl(event.element)
        self:Reopen(target)
    elseif message.action == "UpdateOverride" then
        if event.element.state then
            target.Settings[message.control] = nil
        else
            target.Settings[message.control] = target[message.control]
        end
        self:Reopen(target)
    elseif message.subModule == "Spritor" then
        Spritor:OnGuiEvent(event)
    elseif message.action == "Settings" then
        self:OpenSettings(target)
    elseif message.target == "Task" then
        if message.action == "Remove" then
            self.Global.Remindor.List:Remove(taskIndex)
        elseif message.action == "Drag" then
            local up
            if event.button == defines.mouse_button_type.left then
                up = true
            elseif event.button == defines.mouse_button_type.right then
                up = false
            else
                return
            end

            local newIndex
            if event.shift then
                if up then
                    newIndex = 1
                else
                    newIndex = #self.Global.Remindor.List
                end
            else
                if up then
                    newIndex = math.max(taskIndex - 1, 1)
                else
                    newIndex = math.min(taskIndex + 1, #self.Global.Remindor.List)
                end
            end

            if newIndex == taskIndex then return end
            self.Global.Remindor.List:Remove(taskIndex)
            self.Global.Remindor.List:InsertAt(newIndex, target)
        else
            assert(release)
            return
        end
        self:Reopen()
    elseif message.action == "Closed" then
        if message.subModule == "Settings" then
            self:CloseSettings()
        elseif not message.subModule then
            self:Close()
        end
    end
end

function Class:AddRemindorTask(selection)
    self:EnsureGlobal()
    local key = selection.CommonKey
    local index = self:GetTaskIndex(key)
    local task = index and self.Global.Remindor.List[index] or Task:new(selection, self)
    if index then self.Global.Remindor.List:Remove(index) end
    self.Global.Remindor.List:InsertAt(1, task)
    task:AddSelection(selection)

    if self.Current then
        self:Refresh()
    else
        self:Open()
    end
end

function Class:GetTaskIndex(key)
    for index, task in ipairs(self.Global.Remindor.List) do
        if task.CommonKey == key then return index end
    end
end

function Class:OnSettingsChanged(event)
    self.cache[Class.name].ParentData.IsValid = false
    self:Reopen()
end

function Class:OnMainInventoryChanged(event)
    Spritor:RefreshMainInventoryChanged()
    self:Refresh()
end

function Class:OnStackChanged() end

function Class:OnResearchChanged(event)
    Spritor:RefreshResearchChanged()
    self:Refresh()
end

function Class:RefreshMainInventoryChanged()
    assert(release)
    self:Refresh()
end

function Class:OnStackChanged() end

return Class
