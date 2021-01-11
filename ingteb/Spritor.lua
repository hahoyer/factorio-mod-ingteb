local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local StackOfGoods = require("ingteb.StackOfGoods")

local Class = class:new(
    "Spritor", nil, {
        Site = {get = function(self) return self.Parent.class.name end},
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
        Database = {get = function(self) return self.Parent.Database end},
    }
)

function Class:new(parent)
    return self:adopt{Parent = parent, DynamicElements = Dictionary:new(), DynamicElementsIndex = 1}
end

function Class:GetSpriteButton(target, sprite)
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
        actions = {on_click = {module = self.Site, subModule = self.class.name, action = "Click"}},
        name = target.ClickTarget,
        style = style,
    }
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    if message.action == "Click" then
        return self:OnGuiClick(event)
    else
        assert(release)
        local commonKey = event.element.name
        self:Close()
        self.Parent:PresentTargetByCommonKey(commonKey)
    end
end

function Class:OnGuiClick(event)
    local global = self.Global
    local player = self.Player

    local target = self.Database:GetProxyFromCommonKey(event.element.name)
    if not target or not target.Prototype then return end

    local action = target:GetAction(event)
    if not action then return end

    if action.Selecting then
        if not action.Entity or not player.pipette_entity(action.Entity.Prototype) then
            player.cursor_ghost = action.Selecting.Prototype
        end
    end

    if action.HandCrafting then player.begin_crafting(action.HandCrafting) end

    if action.Research then
        if action.Multiple then
            local message = self.Database:BeginMulipleQueueResearch(action.Research)
            if message then self:Print(player, message) end
        elseif action.Research.IsReady then
            action.Research:BeginDirectQueueResearch()
        end
    end

    if action.ReminderTask then
        self.Parent.Parent:SelectRemindor(global, action, Helper.GetLocation(event.element))
    end

    if action.Presenting then
        local result = self.Parent.Parent:PresentTarget(action.Presenting)
        return result
    end
end

function Class:StartCollecting()
    self.DynamicElementsIndex = 1
    self.DynamicTargets = Array:new()
    self.DynamicElements = Dictionary:new()
end

function Class:CreateSprite(frame, target, sprite)
    return gui.build(frame, self:GetSpriteButton(target, sprite))
end

function Class:GetHelperText(target)
    if target.GetHelperText then return target:GetHelperText(self.Site) end
    return target.HelperText
end

function Class:CollectForGuiClick(result, target)
    --    global.Links[self.Site][result.index] = target and target.ClickTarget
    if target and (target.IsRefreshRequired or target.HasLocalisedDescriptionPending) then
        result.ref = {"DynamicElements", self.DynamicElementsIndex}
        self.DynamicTargets:Append(target)
        self.DynamicElementsIndex = self.DynamicElementsIndex + 1
    end
    return result
end

function Class:RegisterDynamicTargets(guiElements)
    if guiElements then
        self.DynamicTargets:Select(
            function(target, index)
                self.DynamicElements:AppendForKey(target, guiElements[index])
            end
        )
    end
end

function Class:GetSpriteButtonAndRegister(target, sprite)
    local result = self:GetSpriteButton(target, sprite)
    if target then self:CollectForGuiClick(result, target) end
    return result
end

function Class:CreateSpriteAndRegister(frame, target, sprite)
    return gui.build(frame, self:GetSpriteButtonAndRegister(target, sprite))
end

function Class:UpdateGui(list, target)
    if target.class == StackOfGoods then
        target = StackOfGoods:new(target.Goods, target.Amounts, self.Database)
    else
        target = self.Database:GetProxy(target.class.name, target.Name)
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

function Class:Close()
    self.DynamicElements = Dictionary:new() --
end

function Class:RefreshMainInventoryChanged()
    self.DynamicElements --
    :Where(function(_, target) return target.IsRefreshRequired.MainInventory end) --
    :Select(function(list, target) self:UpdateGui(list, target) end) --
end

function Class:RefreshStackChanged(dataBase) end

function Class:RefreshResearchChanged()
    self.DynamicElements --
    :Where(function(_, target) return target.IsRefreshRequired.Research end) --
    :Select(function(list, target) self:UpdateGui(list, target) end) --
end

function Class:GetTiles(count)
    return Array:FromNumber(count) --
    :Select(function() return {type = "sprite", style = "ingteb-un-button"} end)
end

function Class:GetLinePart(target, count, isRightAligned)
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

function Class:GetLine(target, tooltip)
    local count = target:Count()
    local children = Array:new()
    if target.Technologies then
        children:AppendMany(
            target.Technologies:Select(
                function(element) return self:GetSpriteButtonAndRegister(element) end
            )
        )
    end
    target.StackOfGoods:Select(
        function(element) children:Append(self:GetSpriteButtonAndRegister(element)) end
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
