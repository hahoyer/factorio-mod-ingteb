local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")

-- __DebugAdapter.breakpoint(mesg:LocalisedString)
local EventManager = class:new("core.EventManager")

EventManager.EventDefinesByIndex = Dictionary:new(defines.events) --
:ToDictionary(function(value, key) return {Key = value, Value = key} end) --
:ToArray()

EventManager.property = {
    Player = {
        get = function() return UI.Player end,
        set = function(_, value)

            local lastPlayerIndex = UI.PlayerIndex
            local lastPlayer = UI.Player
            if value then

                if type(value) == "number" then 
                    UI.PlayerIndex = value
                elseif type(value) == "table" and value.object_name == "LuaPlayer" and value then
                    UI.PlayerIndex = value.index
                else 
                    assert(release) 
                end

                if game then UI.Player = game.players[UI.PlayerIndex] end

            else
                assert(release) 
                UI.Player = nil
                UI.PlayerIndex = nil
            end

            assert(lastPlayerIndex == nil or lastPlayerIndex == UI.PlayerIndex)
            assert(lastPlayer == nil or lastPlayer == UI.Player)
        end,
    },
    Global = {get = function(self) return global.Players[UI.PlayerIndex] end},
}

function EventManager:Watch(handler, eventId)
    local instance = self
    return function(...)
        instance :Enter(eventId, ...)
        local result = handler(instance , ...)
        instance :Leave(eventId)
        return result
    end
end

function EventManager:Enter(name, event) self.Active = {name, self.Active} end

function EventManager:Leave(name) self.Active = self.Active[2] end

function EventManager:SetHandler(eventId, handler, register)
    if not self.State then self.State = {} end
    if not handler then register = false end
    if register == nil then register = true end

    local name = type(eventId) == "number" and self.EventDefinesByIndex[eventId] or eventId

    self.State[name] = "activating..." .. tostring(register)

    if register == false then handler = nil end
    local watchedEvent = handler and self:Watch(handler, name) or nil

    local eventRegistrar = event[eventId]
    if eventRegistrar then
        eventRegistrar(watchedEvent)
    else
        event.register(eventId, watchedEvent)
    end

    self.State[name] = register
end

return EventManager

