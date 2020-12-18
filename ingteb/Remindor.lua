local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local recipe = require "recipe"
local Array = Table.Array
local Dictionary = Table.Dictionary
local UI = require("core.UI")
local class = require("core.class")
local SpritorClass = require("ingteb.Spritor")

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
    local taskInformation = self.Target.TaskInformation

    local required = taskInformation.Required
    if required and required:Any() then
        Spritor:CreateLine(headLine, required, {"ingteb-utility.required-for-item"})
    end

    local recipeInformations = taskInformation.Recipes --
    :Where(function(recipe) return not self.Filter[recipe.Recipe.CommonKey] end)

    if recipeInformations and recipeInformations:Any() then
        local bodyFrame = vertical.add {type = "flow", direction = "horizontal"}
        bodyFrame.add {type = "line", direction = "vertical"}
        local body = bodyFrame.add {type = "flow", direction = "vertical"}
        recipeInformations:Select(
            function(recipeInformation)
                self:CreateRecipeEntry(
                    body, recipeInformation, Array:new{required}, recipeInformations:Count() == 1
                )
            end
        )
    end

end

function Task:CreateRecipeEntry(body, recipeInformation, exceptions, isSingleEntry)
    local required = recipeInformation.Required
    exceptions:Select(function(exception) required = required:Except(exception) end)

    local exceptions = exceptions:Concat{required}

    if not isSingleEntry or required:Any() then
        local headLine = body.add {type = "flow", direction = "horizontal"}
        self:CreateCloseButton(
            headLine, {
                type = "remove-option",
                key = self.Target.CommonKey,
                subKey = recipeInformation.Recipe.CommonKey,
            }
        )
        headLine.add {type = "sprite", sprite = "utility/close_black", tooltip = "press to close."}
        Spritor:CreateSpriteAndRegister(headLine, recipeInformation.Recipe)
        Spritor:CreateLine(headLine, required, {"ingteb-utility.required-technologies-for-recipe"})

        local bodyFrame = body.add {type = "flow", direction = "horizontal"}
        bodyFrame.add {type = "line", direction = "vertical"}
        body = bodyFrame.add {type = "flow", direction = "vertical"}
    end

    recipeInformation.Workers--
    :Where(function(worker) return not self.Filter[worker.Worker.CommonKey] end)--
    :Select(
        function(workerInformation)
            self:CreateWorkerEntry(body, workerInformation, exceptions)
        end
    )
end

function Task:CreateWorkerEntry(frame, workerInformation, exceptions)
    local headLine = frame.add {type = "flow", direction = "horizontal"}
    self:CreateCloseButton(
        headLine, {
            type = "remove-option",
            key = self.Target.CommonKey,
            subKey = workerInformation.Worker.CommonKey,
        }
    )
    Spritor:CreateSpriteAndRegister(headLine, workerInformation.Worker)
    if not workerInformation.Required then
        assert(release or not workerInformation.Recipes)
        return
    end

    local required = workerInformation.Required
    exceptions:Select(function(exception) required = required:Except(exception) end)
    Spritor:CreateLine(headLine, required, {"ingteb-utility.required-technologies-for-worker"})
    local exceptions = exceptions:Concat{required}

    if true then return end

    workerInformation.Recipes:Select(
        function(recipeInformation)
            self:CreateRecipeEntry(frame, recipeInformation, exceptions)
        end
    )
end

function Task:new(target)
    local instance = Task:adopt{
        Target = target,
        Filter = {}
    }
    return instance
end

function Remindor:EnsureGlobal()
    if not global.Remindor then
        global.Remindor = {Dictionary = {}, List = Array:new{}, Links = Dictionary:new{}}
    end
end

function Remindor:SetTask(player, target)
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

function Remindor:OnGuiClick(player, event)
    local functionData = global.Remindor.Links[event.element.index]
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
    global.Remindor.Link = Dictionary:new{}
    Remindor.Frame.Tasks.clear()
    global.Remindor.List:Select(function(task) task:CreatePanel(Remindor.Frame.Tasks) end)
end

function Remindor:RefreshResearchChanged() self:Refresh() end

function Remindor:new(frame)
    Remindor.Frame = frame.add {type = "frame", name = "Remindor", direction = "vertical"}
    Spritor = SpritorClass:new("Remindor")
    local head = Remindor.Frame.add {type = "flow", direction = "horizontal"}
    head.add {type = "label", caption = {"ingteb-utility.reminder-tasks"}}
    Remindor.Frame.add {type = "flow", name = "Tasks", direction = "vertical"}
    return Remindor.Frame
end

return Remindor
