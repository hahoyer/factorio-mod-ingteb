local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")

local Class = class:new(
    "RemindorSettings", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
        Database = {get = function(self) return self.Parent.Database end},
        Local = {get = function(self) return self.Parent.LocalSettings end},
        Default = {get = function(self) return self.Parent.DefaultSettings end},
        IsIrrelevant = {get = function(self) return self.Parent.IsIrrelevantSettings end},

    }
)

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
            self, "AutoCrafting", {"ingteb-utility.auto-crafting"}, Constants.AutoCraftingVariants,
                {
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

function Class:GetHelp(tag)
    local localisedNames = {
        AutoResearch = "ingteb-utility.select-remindor-autoresearch-help",
        AutoCrafting = "ingteb-utility.select-remindor-autocrafting-help",
        RemoveTaskWhenFulfilled = "ingteb-utility.select-remindor-remove-when-fulfilled-help",
    }

    local localisedNameForValues = {
        [true] = "ingteb-utility.settings-switch-on",
        [false] = "ingteb-utility.settings-switch-off",
        off = "string-mod-setting.ingteb_reminder-task-autocrafting-off",
        ["1"] = "string-mod-setting.ingteb_reminder-task-autocrafting-1",
        ["5"] = "string-mod-setting.ingteb_reminder-task-autocrafting-5",
        all = "string-mod-setting.ingteb_reminder-task-autocrafting-all",
    }

    local nextValue = {
        [true] = false,
        [false] = true,
        off = "1",
        ["1"] = "5",
        ["5"] = "all",
        all = "off",
    }

    local additionalLines = Array:new{}

    local currentValue = self.Local[tag]
    local valueByDefault = self.Default[tag]
    local nextValue = nextValue[currentValue]
    if nextValue ~= nil then
        additionalLines:Append(
            UI.GetHelpTextForButtons({localisedNameForValues[nextValue]}, "--- l")
        )
    end

    local nextValueByDefault = {localisedNameForValues[valueByDefault]}
    local defaultClick = currentValue == nil and "ingteb-utility.settings-activate"
                             or "ingteb-utility.settings-deactivate"
    additionalLines:Append(UI.GetHelpTextForButtons({defaultClick, nextValueByDefault}, "--- r"))

    local actualValue = currentValue or valueByDefault
    return Helper.ConcatLocalisedText(
        {localisedNames[tag], {localisedNameForValues[actualValue]}}, additionalLines
    )

end

function Class:GetNumber(tag)
    if tag == "AutoCrafting" then
        local value = self.Local[tag]
        if value == nil then value = self.Default[tag] end
        local result = tonumber(value)
        if result ~= 0 then return result end
    end
end

function Class:GetButton(tag, spriteList, help)
    if self.IsIrrelevant and self.IsIrrelevant[tag] then
        return {
            type = "sprite",
            style = "ingteb-un-button",
            style_mods = {size = self.Parameters.ButtonSize},

        }
    end
    local value = self.Local[tag]
    if value == nil then value = self.Default[tag] end
    local sprite = spriteList[(value == false or value == "off") and 1 or 2]

    return {
        type = "sprite-button",
        sprite = sprite,
        ref = {tag},
        style = self.Local[tag] ~= nil and "ingteb-light-button" or "slot_button",
        tooltip = help,
        style_mods = {size = self.Parameters.ButtonSize},
        number = self:GetNumber(tag),
        actions = {
            on_click = {
                module = "Remindor",
                action = "SettingsClick",
                target = self.Parent.class.name,
                tag = tag,
                key = self.Parent.CommonKey,
            },
        },
    }
end

function Class:OnClick(event)
    local message = gui.read_action(event)
    local tag = message.tag
    local value = self.Local[tag]
    local newValue

    if event.button == defines.mouse_button_type.right then
        if value == nil then newValue = self.Default[tag] end
    elseif self.Local[tag] ~= nil then
        if tag == "AutoCrafting" then
            local index = Array:new(Constants.AutoCraftingVariants):IndexWhere(
                function(variant) return value == variant end
            )
            local newIndex = index % #Constants.AutoCraftingVariants + 1
            newValue = Constants.AutoCraftingVariants[newIndex]
        else
            newValue = not value
        end
    end

    self.Local[tag] = newValue
end

function Class:GetGui()
    return {
        type = "flow",
        direction = "horizontal",
        children = {
            self:GetButton(
                "AutoResearch", {"utility.technology_black", "utility.technology_white"},
                    self:GetHelp("AutoResearch")
            ),
            self:GetButton(
                "AutoCrafting",
                    {"utility.slot_icon_robot_material_black", "utility.slot_icon_robot_material"},
                    self:GetHelp("AutoCrafting")
            ),
            self:GetButton(
                "RemoveTaskWhenFulfilled", {"utility.trash", "utility.trash_white"},
                    self:GetHelp("RemoveTaskWhenFulfilled")
            ),
        },
    }

end

function Class:new(parent, parameters) return self:adopt{Parent = parent, Parameters = parameters} end

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
