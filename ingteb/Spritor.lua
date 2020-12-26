local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local gui = require "core.gui"
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local StackOfGoods = require("ingteb.StackOfGoods")

local Spritor = class:new("Spritor")

function Spritor:new(site) return self:adopt{DynamicElements = Dictionary:new(), Site = site} end

function Spritor:GetSpriteButton(target, sprite)
    local style = Helper.SpriteStyleFromCode(target and target.SpriteStyle)

    if not target then return {type = "sprite-button", sprite = sprite, style = style} end
    local sprite = target.SpriteName
    if sprite == "fuel-category/chemical" then sprite = "chemical" end

    return {
        type = "sprite-button",
        tooltip = self:GetHelperText(target),
        sprite = sprite,
        number = target.NumberOnSprite,
        show_percent_for_small_numbers = target.UsePercentage,
        handlers = "Spritor.Button",
        name = target.ClickTarget,
        style = style,
    }
end

function Spritor:CreateSprite(frame, target, sprite)
    return gui.build(frame, self:GetSpriteButton(target, sprite))
end

function Spritor:GetHelperText(target)
    if target.GetHelperText then return target:GetHelperText(self.Site) end
    return target.HelperText
end

function Spritor:RegisterTargetForGuiClick(result, target)
    --    global.Links[self.Site][result.index] = target and target.ClickTarget
    if target and (target.IsRefreshRequired or target.HasLocalisedDescriptionPending) then
        self.DynamicElements:AppendForKey(target, result)
    end
    return result
end

function Spritor:GetSpriteButtonAndRegister(target, sprite)
    local result = self:GetSpriteButton(target, sprite)
    if target then self:RegisterTargetForGuiClick(result, target) end
    return result
end

function Spritor:CreateSpriteAndRegister(frame, target, sprite)
    return gui.build(frame, self:GetSpriteButtonAndRegister(target, sprite))
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

function Spritor:GetTiles(count)
    return Array:FromNumber(count) --
    :Select(function() return {type = "sprite", style = "ingteb-un-button"} end)
end

function Spritor:GetLinePart(target, count, isRightAligned)
    if not count then count = math.min(6, target:Count()) end

    local children = Array:new()
    children:AppendMany(
        target:Select(function(element) return self:GetSpriteButtonAndRegister(element) end)
    )
    if not isRightAligned then children:AppendMany(self:GetTiles(count - target:Count())) end

    local result = {
        type = "flow",
        direction = "horizontal",
        style = isRightAligned and "ingteb-flow-right" or nil,
        children = children,
    }

    if target:Count() <= count then return result end
    return {
        type = "scroll-pane",
        direction = "horizontal",
        vertical_scroll_policy = "never",
        style = "ingteb-scroll-6x1",
        children = {result},
    }

end

function Spritor:GetLine(target, tooltip)
    local count = target:Count()
    local children = Array:new()
    if target.Technologies then
        children:AppendMany(
            target.Technologies:Select(
                function(element) return self:GetSpriteButtonAndRegister(element) end
            )
        )
    end
    target.StackOfGoods:Select(function(element) return self:GetSpriteButtonAndRegister(element) end)

    local scrollFrame = {
        type = count > 6 and "scroll-pane" or "flow",
        direction = "horizontal",
        vertical_scroll_policy = "never",
        style = "ingteb-scroll-6x1",
        children = {{type = "flow", direction = "horizontal", children = children}},
    }

    if count > 0 then
        return {
            type = "flow",
            direction = "horizontal",
            children = {scrollFrame, {type = "sprite", sprite = "info", tooltip = tooltip}},
        }
    end
    return scrollFrame
end

return Spritor
