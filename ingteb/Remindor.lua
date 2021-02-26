local mod_gui = require("mod-gui")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local RemindorTask = require("ingteb.RemindorTask")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local SpritorClass = require("ingteb.Spritor")
local Task = require("ingteb.RemindorTask")
local Settings = require("ingteb.RemindorSettings")

local Class = class:new(
    "Remindor", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
        Database = {get = function(self) return self.Parent.Database end},
        AutoResearch = {
            get = function(self)
                return self.ParentData.Settings.AutoResearch
            end,
        },
        AutoCrafting = {
            get = function(self)
                return self.ParentData.Settings.AutoCrafting
            end,
        },
        RemoveTaskWhenFulfilled = {
            get = function(self)
                return self.ParentData.Settings.RemoveTaskWhenFulfilled
            end,
        },
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

function Class:RestoreFromSave(parent)
    self.Parent = parent
    if not self.Global.Remindor then self.Global.Remindor = {} end
    local current = mod_gui.get_frame_flow(self.Player)[self.class.name]
    local list = self.Global.Remindor.List or {}
    self.Global.Remindor.List = Array:new()
    for _, task in ipairs(list) do
        self.Global.Remindor.List:Append(Task:new(RemindorTask.GetSelection(task), self))
    end

    if current then
        current.destroy()
        self:Open()
    end
    self:Refresh()
end

function Class:Toggle()
    if self.Current then
        self:Close()
    else
        self:Open()
        self:Refresh()
    end
end

function Class:Close()
    if not self.Current then return end
    self.Current.destroy()
    self.Current = nil
    self.Tasks = nil
    Spritor:Close()
end

function Class:Open()
    local result = Helper.CreateLeftSideFrameWithContent(
        self, --
        {
            type = "flow",
            ref = {"Tasks"},
            direction = "vertical",
            style_mods = {horizontally_stretchable = "on"},
        }, --
        {"ingteb-utility.reminder-tasks"} --
    )
    self.Tasks = result.Tasks
    self.Current = result.Main
    self:Refresh()
end

function Class:Reopen()
    if self.Current then
        self:Close()
        self:Open()
    end
    self:Refresh()
end

local isRefreshActive
local repeatAutoRefresh 

function Class:Refresh()
    if isRefreshActive then 
        repeatAutoRefresh = true
        return 
    end
    isRefreshActive = true
    repeat
        repeatAutoRefresh = false
        self:ForceRefresh()
    until  not repeatAutoRefresh
    isRefreshActive = false
end

function Class:ForceRefresh()
    self.Global.Remindor.Links = Dictionary:new{}
    if self.Tasks then self.Tasks.clear() end

    if self.Global.Remindor.List then
        self.Global.Remindor.List = self.Global.Remindor.List:Where(
            function(task) return task.IsRelevant end
        )
        if self.Current then
            local data = {}
            local required = {Things = 0, Settings = {}}
            self.Global.Remindor.List:Select(
                function(task) task:ScanRequired(required) end
            )
            self.MaximumRequiredCount = 

            self.Global.Remindor.List:Select(
                function(task, index)
                    task:CreatePanel(
                        self.Tasks, task.CommonKey, data, index == 1,
                            index == #self.Global.Remindor.List, required
                    )
                end
            )
        end
        self.Global.Remindor.List:Select(function(task) task:AutomaticActions() end)
    else
        self.Global.Remindor.List = Array:new{}
    end
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
    local target = self.Global.Remindor.List[taskIndex] 
    self.Global.Remindor.List:Remove(taskIndex)
    self.Global.Remindor.List:InsertAt(newIndex, target)
    self:Reopen()
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    local key = message.key or event.element.parent.name
    local taskIndex = message.target == "Task" and self:GetTaskIndex(key) or nil
    dassert(message.target ~= "Task" or taskIndex)
    local target = taskIndex and self.Global.Remindor.List[taskIndex] or self

    if message.action == "Click" then
        self.Parent:OnGuiClick(event)
    elseif message.action == "SettingsClick" then
        if message.target == "SelectRemindor" then
            self.Parent.Modules.SelectRemindor.Settings:OnClick(event)
            self.Parent.Modules.SelectRemindor:Reopen()
        elseif message.target == "Task" then
            target.SettingsGui:OnClick(event)
            self:Reopen()
        else
            dassert()
        end
    elseif message.target == "Task" then
        if message.action == "Remove" then
            self.Global.Remindor.List:Remove(taskIndex)
            self:Reopen()
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
    local task = index and self.Global.Remindor.List[index] or Task:new(selection, self)
    if index then
        task = self.Global.Remindor.List[index]
        self.Global.Remindor.List:Remove(index)
        task:AddSelection(selection)
    else
        task = Task:new(selection, self)
    end
    self.Global.Remindor.List:InsertAt(1, task)

    if not self.Current then self:Open() end
    self:Refresh()
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

function Class:OnStackChanged() self:Refresh() end

function Class:OnResearchChanged(event)
    Spritor:RefreshResearchChanged()
    self:Refresh()
end

function Class:RefreshMainInventoryChanged()
    dassert()
    self:Refresh()
end

return Class
