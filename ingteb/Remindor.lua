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
        RemoveTaskWhenFullfilled = {
            get = function(self)
                if self.Settings.RemoveTaskWhenFullfilled ~= nil then
                    return self.Settings.RemoveTaskWhenFullfilled
                end
                return self.ParentData.Settings.RemoveTaskWhenFullfilled
            end,
        },
        HelperTextSettings = {
            get = function(self)
                local result = ""
                if self.AutoResearch then result = result .. "\nAutoResearch" end
                if self.AutoCrafting ~= 1 then
                    result = result .. "\nAutocrafting" .. self.AutoCrafting
                end
                if self.RemoveTaskWhenFullfilled then
                    result = result .. "\nRemoveTaskWhenFullfilled"
                end
                return result
            end,
        },
    }
)

function Class:new(parent)
    local self = self:adopt{
        Parent = parent,
        ParentData = {
            Settings = {AutoResearch = true, AutoCrafting = 2, RemoveTaskWhenFullfilled = true},
        },
        Settings = {},
    }
    Spritor = SpritorClass:new(self)
    return self
end

function Class:CloseSettings()
    if not self.CurrentSettings then return end
    self.CurrentSettings.destroy()
    self.ParentScreen.ignored_by_interaction = nil
    self.Player.opened = self.ParentScreen
    self.CurrentSettings = nil
    self:Refresh()
end

function Class:OpenSettings(target)
    self:CloseSettings()
    self.CurrentSettings = Settings.Open(self, target or self)
end

function Class:RestoreFromSave(parent)
    self.Parent = parent
    mod_gui.get_frame_flow(self.Player)[self.class.name].destroy()
    local list = self.Global.Remindor.List
    self.Global.Remindor.List = Array:new()
    for _, task in ipairs(list) do
        self.Global.Remindor.List:Append(Task:new(RemindorTask.GetSelection(task), self))
    end
    self:Open()
end

function Class:Toggle()
    if self.Current then
        self:Close()
    else
        self:Open()
    end
end

function Class:Close()
    if not self.Current then return end
    self.CloseSettings()
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

function Class:Refresh()
    self:EnsureGlobal()
    self.Global.Remindor.Links = Dictionary:new{}
    if self.Tasks then self.Tasks.clear() end
    local data = {}

    self.Global.Remindor.List = self.Global.Remindor.List:Where(
        function(task) return task.IsRelevant end
    )
    self.Global.Remindor.List:Select(
        function(task) task:CreatePanel(self.Tasks, task.CommonKey, data) end
    )
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
        return element.selected_index
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
        self:OpenSettings(target)
    elseif message.action == "UpdateOverride" then
        if event.element.state then
            target.Settings[message.control] = nil
        else
            target.Settings[message.control] = target[message.control]
        end
        self:OpenSettings(target)
    elseif message.action == "Settings" then
        self:OpenSettings(target)
    elseif message.target == "Task" then
        if message.action == "Remove" then
            self:CloseTask(taskIndex)
        else
            assert(release)
        end
    elseif message.action == "Closed" then
        if message.subModule == "Settings" then
            self:CloseSettings()
        elseif not message.subModule then
            self:Close()
        end
    end
end

function Class:SetTask(selection)
    self:EnsureGlobal()
    local key = selection.CommonKey
    local index = self:GetTaskIndex(key)
    local task = index and self.Global.Remindor.List[index] or Task:new(selection, self)
    if index then self.Global.Remindor.List:Remove(index) end
    self.Global.Remindor.List:InsertAt(1, task)

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

-------------------------

function Class:RefreshClasses(frame, database, global)
    assert(release)
    if not self.Global then self.Global = global end
    assert(release or self.Global == global)
    self:EnsureGlobal()
    if getmetatable(self.Global.Remindor.List) then return end

    self.Frame = frame.Tasks
    Spritor = SpritorClass:new(self)
    Dictionary:new(self.Global.Remindor.Links)
    Array:new(self.Global.Remindor.List)
    self.Global.Remindor.List:Select(
        function(task)
            local commonKey = task.Target.CommonKey
            task.Target = database:GetProxyFromCommonKey(commonKey)
            Task:adopt(task)
        end
    )
end

function Class:AssertValidLinks()
    assert(release)
    self.Global.Remindor.Links:Select(
        function(link, key)
            local element = self:GetGuiElement(self.Tasks, key)
            assert(release or not element or element.sprite == "utility/close_black")
        end
    )
end

function Class:GetGuiElement(element, index)
    assert(release)
    if element.index == index then return element end
    for _, child in pairs(element.children) do
        local result = self:GetGuiElement(child, index)
        if result then return result end
    end
end

function Class:CloseTask(index)
    assert(release)
    self:AssertValidLinks()
    self:EnsureGlobal()
    assert(release or index)
    self.Global.Remindor.List:Remove(index)
    self:Refresh()
    if self.Global.Remindor.List == 0 then self:CloseRemindor(global) end
end

function Class:SettingsTask(name)
    assert(release)
    Settings.Open(self.Global.Remindor.List[self:GetTaskIndex(name)])
    assert(true)
end

function Class:ToggleRemoveTask(value)
    assert(release)
    if value == self.Settings.RemoveTaskWhenFullfilled then return end
    self.Settings.RemoveTaskWhenFullfilled = value
    self:Refresh()
end

function Class:ToggleAutoResearch(value)
    assert(release)
    if value == self.Settings.AutoResearch then return end
    self.Settings.AutoResearch = value
    self:Refresh()
end

function Class:UpdateAutoCrafting(value)
    assert(release)
    if value == self.Settings.AutoCrafting then return end
    self.Settings.AutoCrafting = value
    self:Refresh()
end

function Class:RefreshMainInventoryChanged()
    assert(release)
    self:Refresh()
end

function Class:RefreshStackChanged(dataBase) assert(release) end

function Class:RefreshResearchChanged()
    assert(release)
    self:Refresh()
end

return Class
