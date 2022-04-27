local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local StackOfGoods = require("ingteb.StackOfGoods")

--local noWatcher = true

local Class = class:new(
    "Spritor", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
        Database = {get = function(self) return self.Parent.Database end},
        ChangeWatcher = {cache = true, get = function(self) return self.Parent.ChangeWatcher end},
    }
)

function Class:new(parent) return self:adopt{Parent = parent} end

function Class:GetSpriteButton(target, sprite, category)
    local style = Helper.SpriteStyleFromCode(target and target.SpriteStyle)

    if not target then return {type = "sprite-button", sprite = sprite, style = style} end
    local sprite = target.SpriteName
    if sprite == "fuel-category/chemical" then sprite = "chemical" end

    dassert(game.is_valid_sprite_path(sprite))

    return {
        type = "sprite-button",
        tooltip = self:GetHelperText(target),
        sprite = sprite,
        number = category and target.GetNumberOnSprite and target:GetNumberOnSprite(category)
            or target.NumberOnSprite,
        show_percent_for_small_numbers = target.UsePercentage,
        actions = target.ClickTarget and {
            on_click = {
                module = self.Parent.class.name,
                subModule = self.class.name,
                action = "Click",
                key = target.ClickTarget,
            },
        } or nil,
        style = style,
    }
end

function Class:CreateSprite(frame, target, sprite, category)
    return gui.build(frame, self:GetSpriteButton(target, sprite, category))
end

function Class:GetHelperText(target)
    if target.GetHelperText then return target:GetHelperText(self.Parent.class.name) end
    return target.HelperText
end

function Class:GetRespondingSpriteButton(target, sprite, category)
    local result = self:GetSpriteButton(target, sprite, category)
    if target then self:CollectForGuiClick(result, target) end
    return result
end

function Class:CreateSpriteAndRegister(frame, target, sprite)
    return gui.build(frame, self:GetRespondingSpriteButton(target, sprite))
end

function Class:UpdateGui(guiElement, target)
    if not guiElement or not guiElement.valid then return end

    if target.class == StackOfGoods then
        target = StackOfGoods:new(target.Goods, target.Amounts, self.Database)
    else
        target = self.Database:GetProxy(target.class.name, target.Name)
    end
    local helperText = self:GetHelperText(target)
    local number = target.NumberOnSprite
    local style = Helper.SpriteStyleFromCode(target.SpriteStyle)

    guiElement.tooltip = helperText
    guiElement.number = number
    guiElement.style = style
end

function Class:Close() return self.ChangeWatcher:Close(self) end

function Class:StartCollecting()
    if noWatcher then return end
    return self.ChangeWatcher:StartCollecting(self)
end

function Class:CollectForGuiClick(result, target)
    if noWatcher then return end
    if target and (target.IsRefreshRequired or target.HasLocalisedDescriptionPending) then
        local index = self.ChangeWatcher:CollectForGuiClick(self, target)
        result.ref = {"DynamicElements", index}
    end
    return result
end

function Class:RegisterDynamicElements(guiElements)
    if noWatcher then return end
    return self.ChangeWatcher:RegisterDynamicElements(self, guiElements)
end

function Class:GetTiles(count)
    return Array:FromNumber(count) --
    :Select(function() return {type = "sprite", style = "ingteb-un-button"} end)
end

function Class:GetLinePart(target, maximumCount, isRightAligned, tooltip)
    local count = math.min(6, maximumCount or target:Count())

    local children = Array:new()
    children:AppendMany(
        target:Select(
            function(element) return self:GetRespondingSpriteButton(element) end
        )
    )
    if not isRightAligned then children:AppendMany(self:GetTiles(count - target:Count())) end

    local result = {
        type = "flow",
        direction = "horizontal",
        style = isRightAligned and "ingteb-flow-right" or nil,
        tooltip = tooltip,
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

function Class:GetLine(target, tooltip)
    local count = target:Count()
    local children = Array:new()
    if target.Technologies then
        children:AppendMany(
            target.Technologies:Select(
                function(element) return self:GetRespondingSpriteButton(element) end
            )
        )
    end
    target.StackOfGoods:Select(
        function(element) children:Append(self:GetRespondingSpriteButton(element)) end
    )

    local result = {type = "flow", direction = "horizontal", tooltip = tooltip, children = children}
    if count <= 6 then return result end

    return {
        type = "scroll-pane",
        direction = "horizontal",
        vertical_scroll_policy = "never",
        style = "ingteb-scroll-6x1",
        children = {result},
    }

end

return Class
