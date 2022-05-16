local mod_gui = require("mod-gui")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")

local RemindorTask = require("ingteb.RemindorTask")
local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local class = require("core.class")
local Task = require("ingteb.RemindorTask")
local Settings = require("ingteb.RemindorSettings")
local Spritor = require "ingteb.Spritor"

local Class = class:new(
    "Remindor", nil, {
    Player = { get = function(self) return self.Parent.Player end },
    PlayerGlobal = { get = function(self) return self.Parent.PlayerGlobal end },
    Database = { get = function(self) return self.Parent.Database end },
    ChangeWatcher = { get = function(self) return self.Parent.Modules.ChangeWatcher end },
    AutoResearch = { get = function(self) return self.ParentData.Settings.AutoResearch end },
    AutoCrafting = { get = function(self) return self.ParentData.Settings.AutoCrafting end },
    RemoveTaskWhenFulfilled = {
        get = function(self) return self.ParentData.Settings.RemoveTaskWhenFulfilled end,
    },
    ParentData = {
        cache = "player",
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
    TasksGui = {
        get = function(self)
            local gui = self.MainGui
            if gui then return gui.Tasks or gui.children[2] or gui end
        end,
    },
    MainGui = {
        get = function(self)
            local gui = mod_gui.get_frame_flow(self.Player)
            if gui then
                local xreturn = gui[Constants.ModName .. "." .. self.class.name]
                --if xreturn then dlog("Remindor.MainGui =  " .. xreturn.index) end
                return xreturn
            end
        end,
    },
}
)

function Class:new(parent)
    local self = self:adopt { Parent = parent }
    self.Spritor = Spritor:new(self)
    self.Tasks = Array:new()
    return self
end

function Class:CopyTasksToGlobal()
    self.PlayerGlobal.Remindor = {}
    self.PlayerGlobal.Remindor.Tasks = self.Tasks:Select(function(task) return task.Memento end)
end

function Class.SerializeForMigration(tasks)
    return Array:new(tasks):Select(function(task) return Task.GetMemento(task) end)
end

function Class:IsValidTask(task)
    if not self.Database:GetProxyFromCommonKey(task.Target) then return false end
    if not self.Database:GetProxyFromCommonKey(task.Worker) then return false end
    if not self.Database:GetProxyFromCommonKey(task.Recipe) then return false end
    return true
end

function Class:CreateTasksFromGlobal()
    if not self.PlayerGlobal.Remindor then
        self.PlayerGlobal.Remindor = {}
        self.Tasks = Array:new()
        return
    end

    local tasks = self.PlayerGlobal.Remindor.Tasks or {}
    self.PlayerGlobal.Remindor.Tasks = Array:new()
    for _, task in ipairs(tasks) do
        if self:IsValidTask(task) then
            self.Tasks:Append(Task:new(task, self))
        end
    end
end

function Class:OnLoaded(parent)
    self.Parent = parent
    self:CreateTasksFromGlobal()
    self:Refresh()
end

function Class:Toggle()
    if self.MainGui then
        self:Close()
    else
        self:Open()
        self:Refresh()
    end
end

function Class:Close() if self.MainGui then self.MainGui.destroy() end end

function Class:Open()
    local result = Helper.CreateLeftSideFrameWithContent(
        self, --
        {
            type = "flow",
            name = "Tasks",
            ref = { "Tasks" },
            direction = "vertical",
            style_mods = { horizontally_stretchable = "on" },
        }, --
        { "ingteb-utility.reminder-tasks" }--
    )
    -- dassert(self.TasksGui == result.Tasks)
    -- dassert(self.MainGui == result.Main)
end

function Class:Refresh()
    if self.IsRefreshActive then
        -- Will happen because of autoamtic actions
        return
    end

    self.IsRefreshActive = true
    self.Tasks = self.Tasks:Where(function(task) return task.IsRelevant end)
    self:CopyTasksToGlobal()
    if self.MainGui then self:AppendTasks() end
    self.Tasks:Select(function(task) task:AutomaticActions() end)
    self.IsRefreshActive = false
end

function Class:AppendTasks()
    if self.TasksGui then self.TasksGui.clear() end
    self.Spritor:StartCollecting()
    local data = {}
    local required = { Things = 0, Settings = {} }
    self.Tasks:Select(function(task) task:ScanRequired(required) end)
    self.Tasks:Select(
        function(task, index)
        task:CreatePanel(
            self.TasksGui, task.CommonKey, data, index == 1, index == #self.Tasks, required
        )
    end
    )
end

function Class:OnGuiDrag(event)
    local message = gui.read_action(event)
    local key = message.key or event.element.parent.name
    local taskIndex = self:GetTaskIndex(key)

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
            newIndex = #self.Tasks
        end
    else
        if up then
            newIndex = math.max(taskIndex - 1, 1)
        else
            newIndex = math.min(taskIndex + 1, #self.Tasks)
        end
    end

    if newIndex == taskIndex then return end
    local target = self.Tasks[taskIndex]
    self.Tasks:Remove(taskIndex)
    self.Tasks:InsertAt(newIndex, target)
    self:Refresh()
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    local key = message.key or event.element.parent.name
    local taskIndex = message.target == "Task" and self:GetTaskIndex(key) or nil
    dassert(message.target ~= "Task" or taskIndex)
    local target = taskIndex and self.Tasks[taskIndex] or self

    if message.action == "Click" then
        self.Parent:OnGuiClick(event)
    elseif message.action == "SettingsClick" then
        if message.target == "SelectRemindor" then
            self.Parent.Modules.SelectRemindor.Settings:OnClick(event)
            self.Parent.Modules.SelectRemindor:Reopen()
        elseif message.target == "Task" then
            target.SettingsGui:OnClick(event)
            self:Refresh()
        else
            dassert()
        end
    elseif message.target == "Task" then
        if message.action == "Remove" then
            self.Tasks:Remove(taskIndex)
            self:Refresh()
        elseif message.action == "Drag" then
            self:OnGuiDrag(event)
        else
            dassert()
            return
        end
    elseif message.action == "Closed" then
        if message.subModule == "Settings" then
            self:CloseSettings()
        elseif not message.subModule then
            self:Close()
        end
    else
        dassert()
    end
end

function Class:AddRemindorTask(selection)
    local key = selection.CommonKey
    local index = self:GetTaskIndex(key)
    local task
    if index then
        task = self.Tasks[index]
        self.Tasks:Remove(index)
        task:AddSelection(selection)
    else
        task = Task:new(selection, self)
    end
    self.Tasks:InsertAt(1, task)

    if not self.MainGui then self:Open() end
    self:Refresh()
end

function Class:GetTaskIndex(key)
    for index, task in ipairs(self.Tasks) do if task.CommonKey == key then return index end end
end

function Class:OnSettingsChanged()
    self.system.Cache[Class.name].ParentData.IsValid = false
    self:Refresh()
end

function Class:OnStringTranslated() self:Refresh() end

function Class:OnMainInventoryChanged() self:Refresh() end

function Class:OnStackChanged() self:Refresh() end

function Class:OnResearchChanged() self:Refresh() end

return Class
