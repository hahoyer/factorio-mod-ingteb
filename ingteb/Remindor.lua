local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Gui = require "core.gui"
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local SpritorClass = require("ingteb.Spritor")
local RequiredThings = require("ingteb.RequiredThings")

local Task = class:new("Task")

local Remindor = {}

Spritor = {}

function Task:CreateCloseButton(global, frame, functionData)
    local closeButton = frame.add {
        type = "sprite",
        sprite = "utility/close_black",
        tooltip = "press to close.",
    }
    global.Remindor.Links[closeButton.index] = functionData
end

function Task:GetLine(target, required, tooltip)
    return {
        type = "flow",
        direction = "horizontal",
        children = {
            {
                type = "sprite",
                sprite = "utility/close_black",
                ref = {"Remindor", "Task", "CloseButton"},
                tooltip = "press to close.",
            },
            target and Spritor:GetSpriteButtonAndRegister(target) or {type = "empty-widget"},
            Spritor:GetLine(required, tooltip),
        },
    }
end

function Task:CreateLine(global, frame, target, required, functionData, tooltip)
    local data = gui.build(frame, self:GetLine(target, required, tooltip))
    global.Remindor.Links[data.Remindor.Task.CloseButton.index] = functionData
end

function Task:GetRestructuredWorker(worker) return {Worker = worker, Required = worker.Required} end

function Task:GetRestructuredRecipe(recipe)
    local result = {Recipe = recipe, Required = RequiredThings:new()}
    result.Workers = recipe.Category.Workers --
    :Select(
        function(worker)
            local workerData = self:GetRestructuredWorker(worker)
            result.Required:AddOption(workerData.Required)
            return workerData
        end
    )
    return result
end

function Task:GetRequired() return self.Worker.Required:Concat(self.Recipe.Required) end

function Task:new(selection)
    local instance = Task:adopt(selection)
    return instance
end

function Task:CreatePanel(frame, key)
    local guiData = self:GetGui(key)
    gui.build(frame, {guiData})
end

function Task:GetGui(key)
    return {
        type = "frame",
        direction = "horizontal",
        name = key,
        children = {
            Spritor:GetSpriteButtonAndRegister(self.Target),
            Spritor:GetSpriteButtonAndRegister(self.Worker),
            Spritor:GetSpriteButtonAndRegister(self.Recipe),
            Spritor:GetLine(self:GetRequired(), "tooltip"),
            {
                type = "sprite-button",
                sprite = "utility/close_white",
                style = "frame_action_button",
                ref = {"Remindor", "Task", "CloseButton"},
                actions = {on_click = {gui = "Remindor.Task", action = "Closed"}},
                name = key,
                tooltip = "press to close.",
            },

        },
    }
end

function Remindor:EnsureGlobal(global)
    if not global.Remindor then
        global.Remindor = {Dictionary = {}, List = Array:new{}, Links = Dictionary:new{}}
    end
end

function Remindor:RefreshClasses(global, frame, database)
    self:EnsureGlobal(global)
    if getmetatable(global.Remindor.List) then return end

    Remindor.Frame = frame
    Spritor = SpritorClass:new("Remindor")
    Dictionary:new(global.Remindor.Links)
    Array:new(global.Remindor.List)
    global.Remindor.List:Select(
        function(task)
            local commonKey = task.Target.CommonKey
            task.Target = database:GetProxyFromCommonKey(commonKey)
            Task:adopt(task)
        end
    )
end

function Remindor:SetTask(global, selection)
    self:EnsureGlobal(global)
    local key = selection:GetCommonKey()
    local index = global.Remindor.Dictionary[key]
    if not index then
        local task = Task:new(selection)
        global.Remindor.List:Append(task)
        index = #global.Remindor.List
        global.Remindor.Dictionary[key] = index
    end
    self:Refresh(global)
end

function Remindor:RefreshMainInventoryChanged(dataBase) Spritor:RefreshMainInventoryChanged(dataBase) end

function Remindor:RefreshStackChanged(dataBase) end

function Remindor:AssertValidLinks(global)
    global.Remindor.Links:Select(
        function(link, key)
            local element = self:GetGuiElement(self.Frame, key)
            assert(release or not element or element.sprite == "utility/close_black")
        end
    )
end

function Remindor:GetGuiElement(element, index)
    if element.index == index then return element end
    for _, child in pairs(element.children) do
        local result = self:GetGuiElement(child, index)
        if result then return result end
    end
end

function Remindor:OnGuiClick(global, event)
    self:AssertValidLinks()
    self:EnsureGlobal(global)
    local linkIndex = event.element.index
    local functionData = global.Remindor.Links[linkIndex]
    if not functionData then return end
    global.Remindor.Links[linkIndex] = nil
    local index = global.Remindor.Dictionary[functionData.key]
    assert(release or index)
    if functionData.type == "close-task" then
        global.Remindor.Dictionary[functionData.key] = nil
        global.Remindor.List:Remove(index)
    elseif functionData.type == "remove-option" then
        local task = global.Remindor.List[index]
        task:RemoveOption(functionData.subKey)
    else
        assert(release)
    end
    self:Refresh(global)
end

function Remindor:CloseTask(global, name)
    self:AssertValidLinks(global)
    self:EnsureGlobal(global)
    local index = global.Remindor.Dictionary[name]
    assert(release or index)
    global.Remindor.Dictionary[name] = nil
    global.Remindor.List:Remove(index)
    self:Refresh(global)
end

function Remindor:Close() self.Frame = nil end

function Remindor:Refresh(global)
    self:EnsureGlobal(global)
    global.Remindor.Links = Dictionary:new{}
    if self.Frame then self.Frame.Tasks.clear() end
    global.Remindor.List:Select(
        function(task) task:CreatePanel(self.Frame.Tasks, task:GetCommonKey()) end
    )
end

function Remindor:RefreshResearchChanged(global) self:Refresh(global) end

function Remindor:new(frame)
    Spritor = SpritorClass:new("Remindor")
    Remindor.Frame = frame
    gui.build(
        frame, {
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {type = "label", caption = {"ingteb-utility.reminder-tasks"}},
                    {type = "empty-widget", style = "flib_titlebar_drag_handle"},
                    {
                        type = "sprite-button",
                        sprite = "utility/close_white",
                        tooltip = "press to hide.",
                        actions = {on_click = {gui = "Remindor", action = "Closed"}},
                        style = "frame_action_button",
                    },
                },
            },
            {type = "flow", name = "Tasks", direction = "vertical"},
        }
    )

end

return Remindor
