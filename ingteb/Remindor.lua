local mod_gui = require("mod-gui")
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

Task.property = {
    Global = {cache = true, get = function(self) return self.Parent.Global end},
    Player = {cache = true, get = function(self) return self.Parent.Player end},
    Database = {get = function(self) return self.Parent.Database end},
    AutoResearch = {
        get = function(self)
            if self.Settings.AutoResearch ~= nil then return self.Settings.AutoResearch end
            return self.Parent.Settings.AutoResearch
        end,
    },
    AutoCrafting = {
        get = function(self)
            if self.Settings.AutoCrafting ~= nil then return self.Settings.AutoCrafting end
            return self.Parent.Settings.AutoCrafting
        end,
    },
    RemoveTaskWhenFullfilled = {
        get = function(self)
            if self.Settings.RemoveTaskWhenFullfilled ~= nil then
                return self.Settings.RemoveTaskWhenFullfilled
            end
            return self.Parent.Settings.RemoveTaskWhenFullfilled
        end,
    },
    IsRelevant = {
        get = function(self)
            self:CheckAutoResearch()
            self:CheckAutoCrafting()
            return not self.RemoveTaskWhenFullfilled or not self.IsFullfilled
        end,
    },
    IsFullfilled = {
        get = function(self) return self.CountInInventory >= self.Target.Amounts.value end,
    },

    CountInInventory = {
        get = function(self)
            if self.Worker.Name ~= "character" then return 0 end
            return game.players[self.Global.Index].get_item_count(self.Target.Goods.Name)
        end,
    },
}

local Remindor = class:new("Remindor")
Remindor.property = {
    Database = {get = function(self) return self.Parent.Database end},
    AutoResearch = {
        get = function(self)
            if self.Settings.AutoResearch ~= nil then return self.Settings.AutoResearch end
            return self.Parent.Settings.AutoResearch
        end,
    },
    AutoCrafting = {
        get = function(self)
            if self.Settings.AutoCrafting ~= nil then return self.Settings.AutoCrafting end
            return self.Parent.Settings.AutoCrafting
        end,
    },
    RemoveTaskWhenFullfilled = {
        get = function(self)
            if self.Settings.RemoveTaskWhenFullfilled ~= nil then
                return self.Settings.RemoveTaskWhenFullfilled
            end
            return self.Parent.Settings.RemoveTaskWhenFullfilled
        end,
    },
}

function GetCommonSettingsGui(self)
    local guiName = "Remindor.Settings." .. self.class.name
    return {
        type = "frame",
        name = guiName,
        direction = "vertical",
        ref = {"Main"},
        children = {
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {type = "label", caption = {"ingteb-utility.reminder-settings"}},
                    {type = "empty-widget", style = "flib_titlebar_drag_handle", ref = {"DragBar"}},
                    {
                        type = "sprite-button",
                        sprite = "utility/close_white",
                        tooltip = "press to hide.",
                        style = "frame_action_button",
                        actions = {on_click = {gui = guiName, action = "Closed"}},
                    },
                },
            },
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {
                        type = "checkbox",
                        caption = "override",
                        state = self.Settings.AutoResearch ~= nil,
                        actions = {
                            on_checked_state_changed = {
                                module = "Remindor",
                                subModule = self.class.name,
                                action = "UpdateOverride",
                                control = "AutoResearch",
                            },
                        },
                    },
                    {
                        type = "checkbox",
                        caption = "AutoResearch",
                        state = self.AutoResearch,
                        ignored_by_interaction = self.Settings.AutoResearch == nil,
                        actions = {
                            on_checked_state_changed = {
                                module = "Remindor",
                                subModule = self.class.name,
                                action = "Update",
                                control = "AutoResearch",
                            },
                        },
                    },
                },
            },
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {
                        type = "checkbox",
                        caption = "override",
                        state = self.Settings.AutoCrafting ~= nil,
                        actions = {
                            on_checked_state_changed = {
                                module = "Remindor",
                                subModule = self.class.name,
                                action = "UpdateOverride",
                                control = "AutoCrafting",
                            },
                        },
                    },
                    {
                        type = "drop-down",
                        items = {
                            "no auto-crafting",
                            "craft when 1 is possible",
                            "craft when 5 are possible",
                            "craft when requested are possible",
                        },
                        selected_index = self.AutoCrafting,
                        caption = "AutoCrafting",
                        ignored_by_interaction = self.Settings.AutoCrafting == nil,
                        actions = {
                            on_selection_state_changed = {
                                module = "Remindor",
                                subModule = self.class.name,
                                action = "Update",
                                control = "AutoCrafting",
                            },
                        },
                    },
                },
            },
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {
                        type = "checkbox",
                        caption = "override",
                        state = self.Settings.RemoveTaskWhenFullfilled ~= nil,
                        actions = {
                            on_checked_state_changed = {
                                module = "Remindor",
                                subModule = self.class.name,
                                action = "UpdateOverride",
                                control = "RemoveTaskWhenFullfilled",
                            },
                        },
                    },
                    {
                        type = "checkbox",
                        caption = "Remove task when fullfiled",
                        state = self.RemoveTaskWhenFullfilled,
                        ignored_by_interaction = self.Settings.RemoveTaskWhenFullfilled == nil,
                        actions = {
                            on_checked_state_changed = {
                                module = "Remindor",
                                subModule = self.class.name,
                                action = "Update",
                                control = "RemoveTaskWhenFullfilled",
                            },
                        },
                    },
                },
            },
        },
    }
end

function UpdateCommonSettings(self)
    self.Player.opened.destroy()
    OpenCommonSettings(self)
end

function OpenCommonSettings(self)
    local guiData = GetCommonSettingsGui(self)
    local result = gui.build(self.Player.gui.screen, {guiData})
    result.DragBar.drag_target = result.Main

    if not self.Global.Location.RemindorTaskSettings then
        self.Global.Location.RemindorTaskSettings = {x = 200, y = 100}
    end

    result.Main.location = self.Global.Location.RemindorTaskSettings

    self.ParentScreen = self.Player.opened
    self.Global.IsPopup = true
    self.Player.opened = result.Main
    self.Global.IsPopup = nil
    return result.Main
end

function Task:CheckAutoResearch()
    if not self.AutoResearch then return end
    if not self.Recipe.Required.Technologies:Any() then return end

    self.Database:BeginMulipleQueueResearch(self.Recipe.Technology)
end

function Task:CheckAutoCrafting()
    if self.Worker.Name ~= "character" then return end
    local player = game.players[self.Global.Index]
    if player.crafting_queue_size > 0 then return end

    local toDo = self.Target.Amounts.value - self.CountInInventory
    if toDo <= 0 then return end

    if self.AutoCrafting == 1 then
        return
    elseif self.AutoCrafting == 2 then
        toDo = math.min(toDo, 1)
    elseif self.AutoCrafting == 3 then
        toDo = math.min(toDo, 5)
    end

    local craftable = self.Recipe.CraftableCount
    if toDo > craftable then return end
    player.begin_crafting {count = toDo, recipe = self.Recipe.Name}
end

function Task:CreateCloseButton(global, frame, functionData)
    local closeButton = frame.add {
        type = "sprite",
        sprite = "utility/close_black",
        tooltip = "press to close.",
    }
    global.Remindor.Links[closeButton.index] = functionData
end

function Task:EnsureInventory(goods, data)
    local key = goods.CommonKey
    if data[key] then return end
    if goods.class == Item then
        local player = game.players[self.Global.Index]
        data[key] = player.get_item_count(goods.Name)
    else
        data[key] = 0
    end
end

function Task:GetRequired(data)
    return RequiredThings:new(
        self.Recipe.Required.Technologies, --
        self.Recipe.Required.StackOfGoods --
        and self.Recipe.Required.StackOfGoods --
        :Select(
            function(stack, key)
                local result = stack:Clone()
                self:EnsureInventory(stack.Goods, data)
                local inventory = data[key]
                local count = self.Target.Amounts.value * stack.Amounts.value - inventory
                result.Amounts.value = math.max(count, 0)
                if result.Amounts.value == 0 then result.Amounts = nil end
                data[key] = math.max(-count, 0)
                return result
            end
        ) --
        or nil
    )
end

function Task:new(selection, parent)
    local instance = Task:adopt(selection)
    instance.Parent = parent
    instance.Settings = {}
    return instance
end

function Task:CreatePanel(frame, key, data)
    Spritor:StartCollecting()
    local guiData = self:GetGui(key, data)
    local result = gui.build(frame, {guiData})
    Spritor:RegisterDynamicTargets(result.DynamicElements)
end

function Task:GetGui(key, data)
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
                        actions = {
                            on_click = {
                                gui = "Remindor.Task",
                                module = "Remindor",
                                action = "Remove",
                            },
                        },
                        tooltip = "press to close.",
                    },
                    {
                        type = "sprite-button",
                        sprite = "ingteb_settings_white",
                        style = "frame_action_button",
                        style_mods = {size = 17},
                        ref = {"Remindor", "Task", "Settings"},
                        actions = {
                            on_click = {
                                gui = "Remindor.Task",
                                module = "Remindor",
                                action = "Settings",
                            },
                        },
                    },
                },
            },

            Spritor:GetLine(self:GetRequired(data)),
        },
    }
end

function Remindor:EnsureGlobal()
    if not self.Global.Remindor then
        self.Global.Remindor = {List = Array:new{}, Links = Dictionary:new{}}
    end
end

function Remindor:RefreshClasses(frame, database, global)
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

function Remindor:GetTaskIndex(key)
    for index, task in ipairs(self.Global.Remindor.List) do
        if task:GetCommonKey() == key then return index end
    end
end

function Remindor:SetTask(selection)
    self:EnsureGlobal()
    local key = selection:GetCommonKey()
    local index = Remindor:GetTaskIndex(key)
    local task = index and self.Global.Remindor.List[index] or Task:new(selection, self)
    if index then self.Global.Remindor.List:Remove(index) end
    self.Global.Remindor.List:InsertAt(1, task)
    self:Refresh()
end

function Remindor:AssertValidLinks()
    self.Global.Remindor.Links:Select(
        function(link, key)
            local element = self:GetGuiElement(self.Tasks, key)
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

function Remindor:CloseTask(index)
    self:AssertValidLinks()
    self:EnsureGlobal()
    assert(release or index)
    self.Global.Remindor.List:Remove(index)
    self:Refresh()
    if self.Global.Remindor.List == 0 then self:CloseRemindor(global) end
end

function Remindor:OnClose() self.Frame = nil end

function Remindor:SettingsTask(name)
    OpenCommonSettings(self.Global.Remindor.List[Remindor:GetTaskIndex(name)])
    assert(true)
end

function Remindor:ToggleRemoveTask(value)
    if value == self.Settings.RemoveTaskWhenFullfilled then return end
    self.Settings.RemoveTaskWhenFullfilled = value
    self:Refresh()
end

function Remindor:ToggleAutoResearch(value)
    if value == self.Settings.AutoResearch then return end
    self.Settings.AutoResearch = value
    self:Refresh()
end

function Remindor:UpdateAutoCrafting(value)
    if value == self.Settings.AutoCrafting then return end
    self.Settings.AutoCrafting = value
    self:Refresh()
end

function Remindor:Refresh()
    self:EnsureGlobal()
    self.Global.Remindor.Links = Dictionary:new{}
    if self.Tasks then self.Tasks.clear() end
    local data = {}

    self.Global.Remindor.List = self.Global.Remindor.List:Where(
        function(task) return task.IsRelevant end
    )
    self.Global.Remindor.List:Select(
        function(task) task:CreatePanel(self.Tasks, task:GetCommonKey(), data) end
    )
end

function Remindor:RefreshMainInventoryChanged() self:Refresh() end

function Remindor:RefreshStackChanged(dataBase) end

function Remindor:RefreshResearchChanged() self:Refresh() end

function Remindor:GetGui()
    return {
        type = "frame",
        name = "Remindor",
        direction = "vertical",
        ref = {"Main"},
        children = {
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
                        actions = {
                            on_click = {gui = "Remindor", module = "Remindor", action = "Settings"},
                        },
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
            {type = "flow", ref = {"Tasks"}, name = "Tasks", direction = "vertical"},
        },
    }
end

function Remindor:Open(global)
    self = Remindor:adopt{
        Parent = {
            Settings = {AutoResearch = true, AutoCrafting = 2, RemoveTaskWhenFullfilled = true},
        },
        Settings = {},
        Player = game.players[global.Index],
        Global = global,
    }
    Spritor = SpritorClass:new("Remindor")
    return self
end

function Remindor:Open()
    local result = gui.build(mod_gui.get_frame_flow(self.Player), {self:GetGui()})
    self.Tasks = result.Tasks
    self:Refresh()
    return result.Main
end

function Remindor:OnGuiEvent(event)
    local message = gui.read_action(event)
    assert(release or message and message.module == "Remindor")

    if message.gui == "Remindor" then
        if message.action == "Settings" then
            return OpenCommonSettings(self)
        else
            assert(release)
        end
    end

    local subModule
    if message.subModule == "Remindor" then
        subModule = self
    else
        assert(release)
    end

    if message.action == "UpdateOverride" then
        subModule.Settings[message.control] = subModule[message.control]
        UpdateCommonSettings(subModule)
        return
    elseif message.action == "Update" then
        subModule.Settings[message.control] = event.element.selected_index or event.element.state
        UpdateCommonSettings(subModule)
        return
    end

    if message.gui == "Remindor.Task" then
        local index = self:GetTaskIndex(event.element.parent.name)
        if message.action == "Remove" then
            self:CloseTask(index)
        elseif message.action == "Settings" then
            local task = self.Global.Remindor.List[index]
            OpenCommonSettings(task)
        else
            assert(release)
        end
    elseif message.gui == "Remindor" then
        if message.action == "ToggleAutoResearch" then
            self:ToggleAutoResearch(event.element.state)
        elseif message.action == "ToggleRemoveTask" then
            self:ToggleRemoveTask(event.element.state)
        elseif message.action == "AutoCrafting" then
            self:UpdateAutoCrafting(event.element.selected_index)
        else
            assert(release)
        end
    else
        assert(release)
    end
end

return Remindor
