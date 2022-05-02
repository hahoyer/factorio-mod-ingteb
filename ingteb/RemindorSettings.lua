local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Configurations = require "Configurations"
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
        IsRelevant = {get = function(self) return self.Parent.IsRelevantSettings end},

    }
)

function Class:GetHelp(tag)
    local setup = Configurations.Remindor[tag]
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
    if required and not required[tag] then return {} end
    local isRelevant = self.IsRelevant and self.IsRelevant[tag]
    if not isRelevant then
        return {
            {
                type = "sprite",
                style = "ingteb-un-button",
                style_mods = {size = self.Parameters.ButtonSize},
            },
        }
    end
    local value = self.Local[tag]
    if value == nil then value = self.Default[tag] end
    local sprite = Configurations.Remindor[tag].SpriteList[(value == false or value == "off") and 1 or 2]

    return {
        {
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
        newValue = Configurations.Remindor[tag][value].Next
    end

    self.Local[tag] = newValue
end

function Class:GetGui(required)
    return {
        type = "flow",
        direction = "horizontal",
        children = Array:new{
            self:GetButton("AutoResearch", required),
            self:GetButton("AutoCrafting", required),
            self:GetButton("RemoveTaskWhenFulfilled", required),
        }:ConcatMany(),
    }

end

function Class:new(parent, parameters) return self:adopt{Parent = parent, Parameters = parameters} end

return Class
