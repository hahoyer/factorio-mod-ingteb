local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local recipe = require "recipe"
local Array = Table.Array
local Dictionary = Table.Dictionary
local UI = require("core.UI")
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

function Task:CreatePanel(frame)
    local vertical = frame.add {
        type = "frame",
        name = self.Target.CommonKey,
        direction = "vertical",
    }

    local headLine = vertical.add {type = "flow", direction = "horizontal"}
    self:CreateCloseButton(headLine, {type = "close-task", key = self.Target.CommonKey})
    Spritor:CreateSpriteAndRegister(headLine, self.Target)

    local recipes = self.Target.Recipes --
    :Where(function(recipe) return not self.Filter[recipe.CommonKey] end)
    if not recipes:Any() then return end

    local bodyFrame = vertical.add {type = "flow", direction = "horizontal"}
    bodyFrame.add {type = "line", direction = "vertical"}
    local body = bodyFrame.add {type = "flow", direction = "vertical"}
    recipes:Select(function(recipe) self:CreateRecipeEntry(body, recipe) end)

end

function Task:CreateRecipeEntry(body, recipe)
    local headLine = body.add {type = "flow", direction = "horizontal"}
    self:CreateCloseButton(
        headLine, {type = "remove-option", key = self.Target.CommonKey, subKey = recipe.CommonKey}
    )
    Spritor:CreateSpriteAndRegister(headLine, recipe)
    Spritor:CreateLine(
        headLine, recipe.Required, {"ingteb-utility.required-technologies-for-recipe"}
    )

    local bodyFrame = body.add {type = "flow", direction = "horizontal"}
    bodyFrame.add {type = "line", direction = "vertical"}
    body = bodyFrame.add {type = "flow", direction = "vertical"}

    recipe.Category.Workers --
    :Where(function(worker) return not self.Filter[worker.CommonKey] end) --
    :Select(function(workerInformation) self:CreateWorkerEntry(body, workerInformation) end)
end

function Task:CreateWorkerEntry(frame, worker)
    local headLine = frame.add {type = "flow", direction = "horizontal"}
    self:CreateCloseButton(
        headLine, {type = "remove-option", key = self.Target.CommonKey, subKey = worker.CommonKey}
    )
    Spritor:CreateSpriteAndRegister(headLine, worker)
    if not worker.Required then
        assert(release or not worker.Recipes)
        return
    end

    Spritor:CreateLine(
        headLine, worker.Required, {"ingteb-utility.required-technologies-for-worker"}
    )

    if true then return end

    worker.Recipes:Select(
        function(recipeInformation) self:CreateRecipeEntry(frame, recipeInformation) end
    )
end

function Task:new(target)
    local instance = Task:adopt{Target = target, Filter = {}}
    return instance
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

function Remindor:SetTask(target)
    self:EnsureGlobal()
    local index = global.Remindor.Dictionary[target.CommonKey]
    if not index then
        local task = Task:new(target)
        global.Remindor.List:Append(task)
        index = #global.Remindor.List
        global.Remindor.Dictionary[target.CommonKey] = index
        task:CreatePanel(Remindor.Frame.Tasks)
    end

end

function Remindor:RemoveTask(commonKey)
    self:EnsureGlobal()
    local index = global.Remindor.Dictionary[commonKey]
    assert(release or index)
    global.Remindor.Dictionary[commonKey] = nil
    global.Remindor.List:Remove(index)
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
    local functionData = global.Remindor.Links[event.element.index]
    if not functionData then return end
    local index = global.Remindor.Dictionary[functionData.key]
    if functionData.type == "close-task" then
        global.Remindor.Dictionary[functionData.key] = nil
        self:RemoveTask(index)
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

function Remindor:OnLoad()
    -- Remindor:new()
end

function Remindor:new(frame)
    Spritor = SpritorClass:new("Remindor")
    Remindor.Frame = frame
    local head = frame.add {type = "flow", direction = "horizontal"}
    head.add {type = "label", caption = {"ingteb-utility.reminder-tasks"}}
    frame.add {type = "flow", name = "Tasks", direction = "vertical"}
end

return Remindor
