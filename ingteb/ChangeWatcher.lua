local Constants = require("Constants")

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local class = require("core.class")

local Class = class:new(
    "ChangeWatcher", nil, {
    Player = { get = function(self) return self.Parent.Player end },
    PlayerGlobal = { get = function(self) return self.Parent.PlayerGlobal end },
    Database = { get = function(self) return self.Parent.Database end },
}
)

function Class:new(parent)
    return self:adopt { --
        Parent = parent,
        Data = Dictionary:new {},
    }
end

function Class:Close(target) self.Data[target] = nil end

function Class:StartCollecting(caller)
    self.Data[caller] = { --
        OutdatedLists = Array:new(),
        UpdatedElements = Array:new(),
    }
end

function Class:CollectForGuiClick(caller, target)
    local group = self.Data[caller]
    group.UpdatedElements:Append { Target = target }
    return #group.UpdatedElements
end

function Class:RegisterDynamicElements(caller, guiElements)
    local group = self.Data[caller]
    if guiElements then
        group.UpdatedElements:Select(
            function(element, index)
            local guiElement = guiElements[index]
            if element.GuiElement == nil then
                element.GuiElement = guiElement
            else
                dassert(guiElement == nil or element.GuiElement == guiElement)
            end
        end
        )
    end
end

function Class:OnChanged()
    self.Data:Select(
        function(group)
        group.OutdatedLists:Append(group.UpdatedElements)
        group.UpdatedElements = Array:new {}
    end
    )
end

function Class:GetTopOutdatedList(group)
    if not group.OutdatedLists then return end
    while #group.OutdatedLists > 0 do
        local top = group.OutdatedLists[1]
        local result = top[1]
        top:Remove(1)
        if #top == 0 then group.OutdatedLists:Remove(1) end
        group.UpdatedElements:Append(result)
        return result
    end
end

function Class:OnTick()
    local updateCount = Constants.UpdateCountPerTick
    for caller, group in pairs(self.Data) do
        repeat
            local top = self:GetTopOutdatedList(group)
            if top then
                caller:UpdateGui(top.GuiElement, top.Target)
                updateCount = updateCount - 1
            end
        until not top or updateCount <= 0
    end
end

return Class
