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
local Item = require("ingteb.Item")

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

function Task:EnsureInventory(global, goods, data)
    local key = goods.CommonKey
    if data.Inventory[key] then return end
    if goods.class == Item then
        local player = game.players[global.Index]
        data.Inventory[key] = player.get_item_count(goods.Name)
    else
        data.Inventory[key] = 0
    end
end

function Task:GetRequired(global, data)
    return RequiredThings:new(
        self.Recipe.Required.Technologies, --
        self.Recipe.Required.StackOfGoods --
        and self.Recipe.Required.StackOfGoods --
        :Select(
            function(stack, key)
                local result = stack:Clone()
                Task:EnsureInventory(global, stack.Goods, data)
                local inventory = data.Inventory[key]
                local count = data.Count * stack.Amounts.value - inventory
                result.Amounts.value = math.max(count, 0)
                if result.Amounts.value == 0 then result.Amounts = nil end 
                data.Inventory[key] = math.max(-count, 0)
                return result
            end
        ) --
        or nil
    )
end

function Task:new(selection)
    local instance = Task:adopt(selection)
    return instance
end

function Task:CreatePanel(global, frame, key, data)
    Spritor:StartCollecting()
    local guiData = self:GetGui(global, key, data)
    local result = gui.build(frame, {guiData})
    Spritor:RegisterDynamicTargets(result.DynamicElements)
end

function Task:GetGui(global, key, data)
    return {
        type = "frame",
        direction = "horizontal",
        name = key,
        children = {
            Spritor:GetSpriteButtonAndRegister(self.Target),
            Spritor:GetSpriteButtonAndRegister(self.Worker),
            Spritor:GetSpriteButtonAndRegister(self.Recipe),
            {
                type = "flow",
                direction = "vertical",
                name = key,
                children = {
                    {
                        type = "sprite-button",
                        sprite = "utility/close_white",
                        style = "frame_action_button",
                        style_mods = {size = 17},
                        ref = {"Remindor", "Task", "CloseButton"},
                        actions = {on_click = {gui = "Remindor.Task", action = "Closed"}},
                        tooltip = "press to close.",
                    },
                    {
                        type = "sprite-button",
                        sprite = "ingteb_settings_white",
                        style = "frame_action_button",
                        style_mods = {size = 17},
                        ref = {"Remindor", "Task", "Settings"},
                        actions = {on_click = {gui = "Remindor.Task", action = "Settings"}},
                    },
                },
            },

            Spritor:GetLine(self:GetRequired(global, data)),
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

function Remindor:GetTaskIndex(global, key)
    for index, task in ipairs(global.Remindor.List) do
        if task:GetCommonKey() == key then return index end
    end
end

function Remindor:SetTask(global, selection)
    self:EnsureGlobal(global)
    local key = selection:GetCommonKey()
    if not Remindor:GetTaskIndex(global, key) then
        local task = Task:new(selection)
        global.Remindor.List:InsertAt(1, task)
    end
    self:Refresh(global)
end

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

function Remindor:CloseTask(global, name)
    self:AssertValidLinks(global)
    self:EnsureGlobal(global)
    local index = self:GetTaskIndex(global, name)
    assert(release or index)
    global.Remindor.List:Remove(index)
    self:Refresh(global)
end

function Remindor:Close() self.Frame = nil end

function Remindor:SettingsTask(global, name) end

function Remindor:GetSettingsGui(global)
    return {
        type = "flow",
        direction = "horizontal",
        children = {
            {type = "label", caption = {"ingteb-utility.reminder-tasks"}},
            {type = "empty-widget", style = "flib_titlebar_drag_handle"},
            {
                type = "sprite-button",
                sprite = "ingteb_settings_white",
                style = "frame_action_button",
            },
            {
                type = "sprite-button",
                sprite = "utility/close_white",
                tooltip = "press to hide.",
                style = "frame_action_button",
            },
        },
    }
end

function Remindor:Settings(global)
    local player = game.players[global.Index]
    local guiData = self:GetSettingsGui()
    local result = gui.build(player.gui.relative, {guiData})
end

function Remindor:Refresh(global)
    self:EnsureGlobal(global)
    global.Remindor.Links = Dictionary:new{}
    if self.Frame then self.Frame.Tasks.clear() end
    local data = {Count = 1, Inventory = {}}
    global.Remindor.List:Select(
        function(task) task:CreatePanel(global, self.Frame.Tasks, task:GetCommonKey(), data) end
    )
end

function Remindor:RefreshMainInventoryChanged(global) self:Refresh(global) end

function Remindor:RefreshStackChanged(dataBase) end

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
                        sprite = "ingteb_settings_white",
                        style = "frame_action_button",
                        actions = {on_click = {gui = "Remindor", action = "Settings"}},
                    },
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
