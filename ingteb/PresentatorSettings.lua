local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
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

local function GetGui(self, target)

    local children = Array:new{
        GetGuiForControlGroup(self, "AutoResearch", {"ingteb-utility.auto-research"}),
        GetGuiForControlGroup(
            self, "RemoveTaskWhenFulfilled", {"ingteb-utility.remove-when-fulfilled"}
        ),
    }:ConcatMany()

    return {type = "flow", direction = "vertical", name = self.CommonKey, children = children}
end

function Class.Open(self, target)
    local caption = {"ingteb-utility.presentator-settings"}
    local result = Helper.CreatePopupFrameWithContent(
        self, GetGui(self, target), caption, {subModule = "Settings"}
    )
    return result.Main
end

return Class
