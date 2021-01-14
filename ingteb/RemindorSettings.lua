local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local RemindorTask = require "ingteb.remindortask"
local Array = Table.Array
local Dictionary = Table.Dictionary

local Class = {}

local function GetGuiForDefaultCheckBox(self, controlName)
    return {
        type = "checkbox",
        caption = {"ingteb-utility.default"},
        state = self.Settings[controlName] == nil,
        actions = {
            on_checked_state_changed = {
                module = "Remindor",
                target = self.class.name,
                action = "UpdateOverride",
                control = controlName,
                key = self.CommonKey,
            },
        },
    }
end

local function GetGuiForControl(self, controlName, caption, values, textOfValues)
    local result = {
        type = values and "drop-down" or "checkbox",
        caption = caption,
        ignored_by_interaction = self.Settings[controlName] == nil,
        actions = {
            on_checked_state_changed = {
                module = "Remindor",
                target = self.class.name,
                action = "Update",
                control = controlName,
                key = self.CommonKey,
            },
            on_selection_state_changed = {
                module = "Remindor",
                target = self.class.name,
                action = "Update",
                control = controlName,
                key = self.CommonKey,
            },
        },
    }
    if values then
        result.items = textOfValues
        result.selected_index = Array:new(values):IndexWhere(
            function(value) return value == self[controlName] end
        )
    else
        result.state = self[controlName]
    end
    return result
end

local function GetGuiForControlGroup(self, controlName, caption, values, textOfValues)
    if self[controlName] == nil then return {} end
    return {
        {
            type = "flow",
            direction = "horizontal",
            children = {
                GetGuiForDefaultCheckBox(self, controlName),
                GetGuiForControl(self, controlName, caption, values, textOfValues),
            },
        },
    }
end

local function GetGui(self)

    local children = Array:new{
        GetGuiForControlGroup(self, "AutoResearch", {"ingteb-utility.auto-research"}),
        GetGuiForControlGroup(
            self, "AutoCrafting", {"ingteb-utility.auto-crafting"}, Constants.AutoCraftingVariants, {
                {"string-mod-setting.ingteb_reminder-task-autocrafting-off"},
                {"string-mod-setting.ingteb_reminder-task-autocrafting-1"},
                {"string-mod-setting.ingteb_reminder-task-autocrafting-5"},
                {"string-mod-setting.ingteb_reminder-task-autocrafting-all"},
            }
        ),
        GetGuiForControlGroup(
            self, "RemoveTaskWhenFulfilled", {"ingteb-utility.remove-when-fulfilled"}
        ),
    }:ConcatMany()

    return {type = "flow", direction = "vertical", name = self.CommonKey, children = children}
end

function Class.Open(remindor, self)
    if not self.Global.Location.RemindorSettings then
        self.Global.Location.RemindorSettings = {x = 200, y = 100}
    end
    local caption = {"ingteb-utility.reminder-tasks-settings"}
    if self.class.name == "Task" then
        caption = {
            "",
            caption,
            self.Target.RichTextName,
            self.Worker.RichTextName,
            self.Recipe.RichTextName,
        }
    end
    local result = Helper.CreatePopupFrameWithContent(
        remindor, GetGui(self), caption, {subModule = "Settings"}
    )
    return result.Main
end

return Class
