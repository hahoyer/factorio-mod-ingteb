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

function Task:CreateCloseButton(frame, functionData)
    local closeButton = frame.add {
        type = "sprite",
        sprite = "utility/close_black",
        tooltip = "press to close.",
    }
    global.Remindor.Links[closeButton.index] = functionData
end

function Task:RemoveOption(commonKey) self.Filter[commonKey] = true end

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

function Task:CreateLine(frame, target, required, functionData, tooltip)
    local data = gui.build(frame, self:GetLine(target, required, tooltip))
    global.Remindor.Links[data.Remindor.Task.CloseButton.index] = functionData
end

function Task:GetRestructuredWorker(worker) return {Worker = worker, Required = worker.Required} end

function Task:GetRestructuredRecipe(recipe)
    local result = {Recipe = recipe, Required = RequiredThings:new()}
    result.Workers = recipe.Category.Workers --
    :Where(function(worker) return not self.Filter[worker.CommonKey] end) --
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

function Task:CreatePanel1(frame)
    local vertical = frame.add {
        type = "frame",
        name = self.Target.CommonKey,
        direction = "vertical",
    }

    local data = self:GetRestructuredData()

    Task:CreateLine(
        vertical, data.Target, data.Required, {type = "close-task", key = data.Target.CommonKey},
            {"ingteb-utility.required-for-item"}
    )

    local recipes = data.Recipes
    if not recipes:Any() then return end

    local bodyFrame = vertical.add {type = "flow", direction = "horizontal"}
    bodyFrame.add {type = "line", direction = "vertical"}
    local body = bodyFrame.add {type = "flow", direction = "vertical"}
    recipes:Select(function(recipe) self:CreateRecipeEntry(body, recipe) end)

end

function Task:CreateRecipeEntry(body, recipeData)
    local headLine = body.add {type = "flow", direction = "horizontal"}

    Task:CreateLine(
        headLine, recipeData.Recipe, recipeData.Required, {
            type = "remove-option",
            key = self.Target.CommonKey,
            subKey = recipeData.Recipe.CommonKey,
        }, {"ingteb-utility.required-technologies-for-recipe"}
    )

    local bodyFrame = body.add {type = "flow", direction = "horizontal"}
    bodyFrame.add {type = "line", direction = "vertical"}
    body = bodyFrame.add {type = "flow", direction = "vertical"}

    recipeData.Workers --
    :Where(function(worker) return not self.Filter[worker.CommonKey] end) --
    :Select(function(workerInformation) self:CreateWorkerEntry(body, workerInformation) end)
    body.add {type = "line", direction = "horizontal"}
end

function Task:CreateWorkerEntry(frame, workerData)
    local headLine = frame.add {type = "flow", direction = "horizontal"}

    Task:CreateLine(
        headLine, workerData.Worker, workerData.Required, {
            type = "remove-option",
            key = self.Target.CommonKey,
            subKey = workerData.Worker.CommonKey,
        }, {"ingteb-utility.required-technologies-for-worker"}
    )

    if true then return end

    workerData.Recipes:Select(
        function(recipeInformation) self:CreateRecipeEntry(frame, recipeInformation) end
    )
end

function Task:new(selection)
    local instance = Task:adopt(selection)
    return instance
end

function Task:CreatePanel(frame)
    local guiData = self:GetGui()
    gui.build(frame, {guiData})
end

function Task:GetGui()
    return {
        type = "frame",
        name = self.Target.CommonKey,
        direction = "horizontal",
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
                name = self.Target.CommonKey,
                actions = {
                    on_click = {gui = "Remindor.Task", action = "Closed"},
                },
                tooltip = "press to close.",
            },

        },
    }
end

function Remindor:EnsureGlobal()
    if not global.Remindor then
        global.Remindor = {Dictionary = {}, List = Array:new{}, Links = Dictionary:new{}}
    end
end

function Remindor:RefreshClasses(frame, database)
    self:EnsureGlobal()
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

function Remindor:SetTask(selection)
    self:EnsureGlobal()
    local index = global.Remindor.Dictionary[selection:GetCommonKey()]
    if not index then
        local task = Task:new(selection)
        global.Remindor.List:Append(task)
        index = #global.Remindor.List
        global.Remindor.Dictionary[selection:GetCommonKey()] = index
        task:CreatePanel(Remindor.Frame.Tasks)
    end

end

function Remindor:RefreshMainInventoryChanged(dataBase) Spritor:RefreshMainInventoryChanged(dataBase) end

function Remindor:RefreshStackChanged(dataBase) end

function Remindor:AssertValidLinks()
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

function Remindor:OnGuiClick(event)
    self:AssertValidLinks()
    self:EnsureGlobal()
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
    self:Refresh()
end

function Remindor:Refresh()
    self:EnsureGlobal()
    global.Remindor.Links = Dictionary:new{}
    Remindor.Frame.Tasks.clear()
    global.Remindor.List:Select(function(task) task:CreatePanel(Remindor.Frame.Tasks) end)
end

function Remindor:RefreshResearchChanged() self:Refresh() end

function Remindor:new(frame)
    Spritor = SpritorClass:new("Remindor")
    Remindor.Frame = frame
    local head = frame.add {type = "flow", direction = "horizontal"}
    head.add {type = "label", caption = {"ingteb-utility.reminder-tasks"}}
    frame.add {type = "flow", name = "Tasks", direction = "vertical"}
end

return Remindor
