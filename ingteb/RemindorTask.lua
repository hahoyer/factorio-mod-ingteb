local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local UI = require("core.UI")
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
                if self.Settings.RemoveTaskWhenFulfilled ~= nil then
                    return self.Settings.RemoveTaskWhenFulfilled
                end
                return self.Parent.RemoveTaskWhenFulfilled
            end,
        },
        IsRelevant = {
            get = function(self)
                return not self.RemoveTaskWhenFulfilled or not self.IsFulfilled
            end,
        },
        IsFulfilled = {
            get = function(self) return self.CountAvailable >= self.Target.Amounts.value end,
        },

        CountAvailable = {
            get = function(self)
                return self.Database:CountAvailable(self.Target.Goods.Name)
            end,
        },

        RemainingAmount = {
            get = function(self) return self.Target.Amounts.value - self.CountAvailable end,
        },

        RemainingAmountForAutocrafting = {
            get = function(self)
                if self.Worker.Name ~= "character" then return 0 end
                return self.RemainingAmount
            end,
        },

        CurrentTarget = {
            get = function(self)
                local value = -self.RemainingAmount
                local result = self.Target.Goods:CreateStack(value ~= 0 and {value = value} or nil)
                result.GetCustomHelp = function(result)
                    return {{"", {"ingteb-utility.requested-amount"}, self.Target.Amounts.value}}
                end

                return result
            end,
        },

        HelperTextSettings = {
            get = function(self)
                local result = Array:new{}
                if self.AutoResearch then
                    result:Append("\n")
                    result:Append{"ingteb-utility.auto-research"}
                end
                if self.AutoCrafting and self.AutoCrafting ~= "off" then
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
    }
)

function Class:GetSelection()
    return {
        Target = self.Target.Goods.CommonKey,
        Count = self.Target.Amounts.value,
        Worker = self.Worker.CommonKey,
        Recipe = self.Recipe.CommonKey,
        CommonKey = self.CommonKey,
        Settings = self.Settings,
    }
end

function Class:AddSelection(selection)
    assert(selection.Target == self.Target.Goods.CommonKey)
    assert(selection.Worker == self.Worker.CommonKey)
    assert(selection.Recipe == self.Recipe.CommonKey)
    assert(selection.CommonKey == self.CommonKey)

    local value --
    = (self.Target.Amounts and self.Target.Amounts.value or 0) --
    + (selection.Count or 0)
    self.Target.Amounts = value ~= 0 and {value = value} or nil
end

function Class:new(selection, parent)
    local self = self:adopt{Parent = parent, Settings = selection.Settings or {}}
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

    local toDo = self.RemainingAmountForAutocrafting
    if toDo <= 0 then return end

    if self.AutoCrafting == "off" then
        return
    elseif self.AutoCrafting == "1" then
        toDo = math.min(toDo, 1)
    elseif self.AutoCrafting == "5" then
        toDo = math.min(toDo, 5)
    end

    local craftable = self.Recipe.CraftableCount
    if toDo > craftable then return end
    player.begin_crafting {count = toDo, recipe = self.Recipe.Name}
end

function Class:AutomaticActions()
    self:CheckAutoResearch()
    self:CheckAutoCrafting()
end

function Class:CreatePanel(frame, key, data, isTop, isBottom)
    Spritor:StartCollecting()
    local guiData = self:GetGui(key, data, isTop, isBottom)
    local result = gui.build(frame, {guiData})
    Spritor:RegisterDynamicTargets(result.DynamicElements)
end

local function GetDragTooltip(isTop, isBottom)
    if isTop and isBottom then return end
    return {
        "",
        not isTop and {
            "",
            UI.GetHelpTextForButtons("ingteb-utility.moveTaskToTop", "--S l"),
            "\n",
            UI.GetHelpTextForButtons("ingteb-utility.moveTaskUp", "--- l"),
        } or "",
        not isTop and not isBottom and "\n" or "",
        not isBottom and {
            "",
            UI.GetHelpTextForButtons("ingteb-utility.moveTaskDown", "--- r"),
            "\n",
            UI.GetHelpTextForButtons("ingteb-utility.moveTaskToBottom", "--S r"),
        } or "",
    }
end

function Class:GetGui(key, data, isTop, isBottom)
    return {
        type = "frame",
        direction = "horizontal",
        name = key,
        style_mods = {left_padding = 0},
        children = {
            {
                type = "empty-widget",
                style = "flib_titlebar_drag_handle",
                ref = {"UpDownDragBar"},
                style_mods = {width = 15, height = 40},
                actions = {on_click = {target = "Task", module = "Remindor", action = "Drag"}},
                tooltip = GetDragTooltip(isTop, isBottom),
            },
            Spritor:GetSpriteButtonAndRegister(self.CurrentTarget),
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
        data[key] = self.Player.get_main_inventory().get_item_count(goods.Name)
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
                self:EnsureInventory(stack.Goods, data)
                local inventory = data[key]

                local countByRecipe --
                = self.Recipe.Output --
                :Where(function(stack) return stack.Goods == self.Target.Goods end) --
                :Top().Amounts.value

                local count = inventory --
                - self.RemainingAmountForAutocrafting * stack.Amounts.value / countByRecipe

                local value = math.min(count, 0)
                data[key] = math.max(count, 0)
                return stack.Goods:CreateStack(value ~= 0 and {value = value} or nil)
            end
        ) --
        or nil
    )
end

return Class
