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

local Class = class:new(
    "Task", nil, {
        Global = {get = function(self) return self.Parent.Global end},
        Player = {get = function(self) return self.Parent.Player end},
        Database = {get = function(self) return self.Parent.Database end},
        AutoResearch = {
            get = function(self)
                if not self.Recipe.Required.Technologies:Any() then return end
                if self.Settings.AutoResearch ~= nil then
                    return self.Settings.AutoResearch
                end
                return self.Parent.AutoResearch
            end,
        },
        AutoCrafting = {
            get = function(self)
                if self.Worker.Name ~= "character" then return end
                if self.Settings.AutoCrafting ~= nil then
                    return self.Settings.AutoCrafting
                end
                return self.Parent.AutoCrafting
            end,
        },
        RemoveTaskWhenFulfilled = {
            get = function(self)
                if self.IsFulfilled then return end
                if self.Settings.RemoveTaskWhenFulfilled ~= nil then
                    return self.Settings.RemoveTaskWhenFulfilled
                end
                return self.Parent.RemoveTaskWhenFulfilled
            end,
        },
        IsRelevant = {
            get = function(self)
                self:CheckAutoResearch()
                self:CheckAutoCrafting()
                return not self.RemoveTaskWhenFulfilled or not self.IsFulfilled
            end,
        },
        IsFulfilled = {
            get = function(self)
                return self.CountInInventory >= self.Target.Amounts.value
            end,
        },

        CountInInventory = {
            get = function(self)
                if self.Worker.Name ~= "character" then return 0 end
                return game.players[self.Global.Index].get_item_count(self.Target.Goods.Name)
            end,
        },

        HelperTextSettings = {
            get = function(self)
                local result = Array:new{}
                if self.AutoResearch then
                    result:Append("\n")
                    result:Append{"ingteb-utility.auto-research"}
                end
                if self.AutoCrafting and self.AutoCrafting ~= 1 then
                    local variants = {"", "1", "5", "all"}
                    result:Append("\n")
                    result:Append{"ingteb-utility.auto-crafting-" .. variants[self.AutoCrafting]}
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
    }
)

function Class:GetSelection()
    return {
        Target = self.Target.Goods.CommonKey,
        Count = self.Target.Amounts.value,
        Worker = self.Worker.CommonKey,
        Recipe = self.Recipe.CommonKey,
        CommonKey = self.CommonKey,
    }
end

function Class:new(selection, parent)
    local self = self:adopt{Parent = parent, Settings = {}}
    self.Target = self.Database:GetProxyFromCommonKey(selection.Target):CreateStack{
        value = selection.Count,
    }
    self.Worker = self.Database:GetProxyFromCommonKey(selection.Worker)
    self.Recipe = self.Database:GetProxyFromCommonKey(selection.Recipe)
    self.CommonKey = selection.CommonKey
    return self
end

function Class:CheckAutoResearch()
    if not self.AutoResearch then return end
    if not self.Recipe.Required.Technologies:Any() then return end

    self.Database:BeginMulipleQueueResearch(self.Recipe.Technology)
end

function Class:CheckAutoCrafting()
    if self.Worker.Name ~= "character" then return end
    if self.Recipe.class.name ~= "Recipe" then return end
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
            {
                type = "empty-widget",
                style = "flib_titlebar_drag_handle",
                ref = {"UpDownDragBar"},
                style_mods = {width = 10, height=40, },
                actions = {
                    on_click = {target = "Task", module = "Remindor", action = "Drag"},
                },
    },
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
                            on_click = {target = "Task", module = "Remindor", action = "Remove"},
                        },
                        tooltip = {"gui.close"},
                    },
                    {
                        type = "sprite-button",
                        sprite = "ingteb_settings_white",
                        style = "frame_action_button",
                        style_mods = {size = 17},
                        ref = {"Remindor", "Task", "Settings"},
                        actions = {
                            on_click = {target = "Task", module = "Remindor", action = "Settings"},
                        },
                        tooltip = self.HelperTextSettings,
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
        tooltip = {"gui.close"},
    }
    global.Remindor.Links[closeButton.index] = functionData
end

function Class:EnsureInventory(goods, data)
    local key = goods.CommonKey
    if data[key] then return end
    if goods.class == Item then
        data[key] = self.Player.get_item_count(goods.Name)
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
