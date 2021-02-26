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

local setup = {
    AutoResearch = {
        Name = "ingteb-utility.select-remindor-autoresearch-help",
        SpriteList = {"utility.technology_black", "utility.technology_white"},
        off = {Next = "1", Name = "string-mod-setting.ingteb_reminder-task-autoresearch-off"},
        ["1"] = {Next = "all", Name = "string-mod-setting.ingteb_reminder-task-autoresearch-1"},
        all = {Next = "off", Name = "string-mod-setting.ingteb_reminder-task-autoresearch-all"},
    },
    AutoCrafting = {
        Name = "ingteb-utility.select-remindor-autocrafting-help",
        SpriteList = {"utility.slot_icon_robot_material_black", "utility.slot_icon_robot_material"},
        off = {Next = "1", Name = "string-mod-setting.ingteb_reminder-task-autocrafting-off"},
        ["1"] = {Next = "5", Name = "string-mod-setting.ingteb_reminder-task-autocrafting-1"},
        ["5"] = {Next = "all", Name = "string-mod-setting.ingteb_reminder-task-autocrafting-5"},
        all = {Next = "off", Name = "string-mod-setting.ingteb_reminder-task-autocrafting-all"},
    },
    RemoveTaskWhenFulfilled = {
        Name = "ingteb-utility.select-remindor-remove-when-fulfilled-help",
        SpriteList = {"utility.trash", "utility.trash_white"},
        [true] = {Next = false, Name = "ingteb-utility.settings-switch-on"},
        [false] = {Next = true, Name = "ingteb-utility.settings-switch-off"},
    },
}

function Class:GetHelp(tag)
    local setup = setup[tag]
    local additionalLines = Array:new{}
    local currentValue = self.Local[tag]
    if currentValue ~= nil then
        local nextValue = setup[currentValue].Next
        additionalLines:Append(UI.GetHelpTextForButtons({setup[nextValue].Name}, "--- l"))
    end

    local valueByDefault = self.Default[tag]
    local nextValueByDefault = {setup[valueByDefault].Name}
    local defaultClick = currentValue == nil and "ingteb-utility.settings-activate"
                             or "ingteb-utility.settings-deactivate"
    additionalLines:Append(UI.GetHelpTextForButtons({defaultClick, nextValueByDefault}, "--- r"))

    local actualValue = currentValue or valueByDefault
    return Helper.ConcatLocalisedText({setup.Name, {setup[actualValue].Name}}, additionalLines)

end

function Class:GetNumber(tag)
    local value = self.Local[tag]
    if value == nil then value = self.Default[tag] end
    local result = tonumber(value)
    if result ~= 0 then return result end
end

function Class:GetButton(tag, required)
    local help = self:GetHelp(tag)
    if required and not required[tag] then return {type = "empty-widget"} end
    if self.IsIrrelevant and self.IsIrrelevant[tag] then
        return {
            type = "sprite",
            style = "ingteb-un-button",
            style_mods = {size = self.Parameters.ButtonSize},
        }
    end
    local value = self.Local[tag]
    if value == nil then value = self.Default[tag] end
    local sprite = setup[tag].SpriteList[(value == false or value == "off") and 1 or 2]

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
        newValue = setup[tag][value].Next
    end

    self.Local[tag] = newValue
end

function Class:GetGui(required)
    return {
        type = "flow",
        direction = "horizontal",
        children = {
            self:GetButton("AutoResearch", required),
            self:GetButton("AutoCrafting", required),
            self:GetButton("RemoveTaskWhenFulfilled", required),
        },
    }

end

function Class:new(parent, parameters) return self:adopt{Parent = parent, Parameters = parameters} end

return Class
