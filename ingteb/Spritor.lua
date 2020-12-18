local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local StackOfGoods = require("ingteb.StackOfGoods")

local Spritor = class:new("Spritor")

function Spritor:new(site) return self:adopt{DynamicElements = Dictionary:new(), Site = site} end

function Spritor:CreateSprite(frame, target, sprite)
    local style = Helper.SpriteStyleFromCode(target and target.SpriteStyle)

    if not target then return frame.add {type = "sprite-button", sprite = sprite, style = style} end

    local tooltip = self:GetHelperText(target)
    local sprite = target.SpriteName
    local number = target.NumberOnSprite
    local show_percent_for_small_numbers = target.UsePercentage

    if sprite == "fuel-category/chemical" then sprite = "chemical" end
    return frame.add {
        type = "sprite-button",
        tooltip = tooltip,
        sprite = sprite,
        number = number,
        show_percent_for_small_numbers = show_percent_for_small_numbers,
        style = style,
    }
end

function Spritor:GetHelperText(target)
    if target.GetHelperText then return target:GetHelperText(self.Site) end
    return target.HelperText
end

function Spritor:RegisterTargetForGuiClick(result, target)
    global.Links[self.Site][result.index] = target and target.ClickTarget
    if target and (target.IsRefreshRequired or target.HasLocalisedDescriptionPending) then
        self.DynamicElements:AppendForKey(target, result)
    end
    return result
end

function Spritor:CreateSpriteAndRegister(frame, target, sprite)
    local result = self:CreateSprite(frame, target, sprite)
    if target then self:RegisterTargetForGuiClick(result, target) end
    return result
end

function Spritor:UpdateGui(list, target, dataBase)
    if target.class == StackOfGoods then
        target = StackOfGoods:new(target.Goods, target.Amounts, dataBase)
    else
        target = dataBase:GetProxy(target.class.name, target.Name)
    end
    local helperText = self:GetHelperText(target)
    local number = target.NumberOnSprite
    local style = Helper.SpriteStyleFromCode(target.SpriteStyle)

    for _, guiElement in pairs(list) do
        if guiElement.valid then
            guiElement.tooltip = helperText
            guiElement.number = number
            guiElement.style = style
        end
    end
end

function Spritor:Close()
    self.DynamicElements = Dictionary:new() --
end

function Spritor:RefreshMainInventoryChanged(dataBase)
    self.DynamicElements --
    :Where(function(_, target) return target.IsRefreshRequired.MainInventory end) --
    :Select(function(list, target) self:UpdateGui(list, target, dataBase) end) --
end

function Spritor:RefreshStackChanged(dataBase) end

function Spritor:RefreshResearchChanged(dataBase)
    self.DynamicElements --
    :Where(function(_, target) return target.IsRefreshRequired.Research end) --
    :Select(function(list, target) self:UpdateGui(list, target, dataBase) end) --
end

function Spritor:DummyTiles(frame, count)
    for _ = 1, count do --
        frame.add {type = "sprite", style = "ingteb-un-button"}
    end
end

function Spritor:CreateLinePart(frame, target, count, isRightAligned)
    local scrollFrame = frame
    if not count then count = math.min(6, target:Count()) end
    if target:Count() > count then
        scrollFrame = frame.add {
            type = "scroll-pane",
            direction = "horizontal",
            vertical_scroll_policy = "never",
            style = "ingteb-scroll-6x1",
        }
    end

    local subPanel = scrollFrame.add {
        type = "flow",
        direction = "horizontal",
        style = isRightAligned and "ingteb-flow-right" or nil,
    }

    target:Select(function(element) return self:CreateSpriteAndRegister(subPanel, element) end)

    if isRightAligned then return end

    self:DummyTiles(subPanel, count - target:Count())
end

function Spritor:CreateLine(frame, target, tooltip)
    local scrollFrame = frame
    local count = target.Technologies:Count() + target.StackOfGoods:Count()
    if count > 6 then
        scrollFrame = frame.add {
            type = "scroll-pane",
            direction = "horizontal",
            vertical_scroll_policy = "never",
            style = "ingteb-scroll-6x1",
        }
    end

    local subPanel = scrollFrame.add {type = "flow", direction = "horizontal"}
    target.Technologies:Select(function(element) return self:CreateSpriteAndRegister(subPanel, element) end)
    target.StackOfGoods:Select(function(element) return self:CreateSpriteAndRegister(subPanel, element) end)
    if count > 0 then frame.add {type = "sprite", sprite = "info", tooltip = tooltip} end
end

return Spritor
