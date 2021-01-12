local mod_gui = require("mod-gui")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local RequiredThings = require("ingteb.RequiredThings")
local Item = require("ingteb.Item")

local Class = class:new("Task")

Class.property = {
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

function Class:new(selection, parent)
    local self = self:adopt(selection)
    self.Parent = parent
    self.Settings = {}
    return self
end

function Class:CheckAutoResearch()
    if not self.AutoResearch then return end
    if not self.Recipe.Required.Technologies:Any() then return end

    self.Database:BeginMulipleQueueResearch(self.Recipe.Technology)
end

function Class:CheckAutoCrafting()
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

function Class:CreatePanel(frame, key, data)
    Spritor:StartCollecting()
    local guiData = self:GetGui(key, data)
    local result = gui.build(frame, {guiData})
    Spritor:RegisterDynamicTargets(result.DynamicElements)
end

function Class:GetGui(key, data)
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
                                subModule = "Task",
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
                                subModule = "Task",
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

function Class:CreateCloseButton(global, frame, functionData)
    local closeButton = frame.add {
        type = "sprite",
        sprite = "utility/close_black",
        tooltip = "press to close.",
    }
    global.Remindor.Links[closeButton.index] = functionData
end

function Class:EnsureInventory(goods, data)
    local key = goods.CommonKey
    if data[key] then return end
    if goods.class == Item then
        local player = game.players[self.Global.Index]
        data[key] = player.get_item_count(goods.Name)
    else
        data[key] = 0
    end
end

function Class:GetRequired(data)
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

return Class
