local events = require("__flib__.event")
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
                    assert()
                end

                if game then UI.Player = game.players[UI.PlayerIndex] end

            else
                assert()
                UI.Player = nil
                UI.PlayerIndex = nil
            end

            assert(lastPlayerIndex == nil or lastPlayerIndex == UI.PlayerIndex)
            assert(lastPlayer == nil or lastPlayer == UI.Player)
        end,
    },
    Global = {get = function(self) return global.Players[UI.PlayerIndex] end},
}

function EventManager:Execute(eventId, eventName)
    local instance = self
    return function(...)
        local handlers = self.Handlers[eventName]
        for identifier, handler in pairs(handlers) do
            instance:Enter(eventName, eventId, identifier)
            local result = handler(instance, ...)
            instance:Leave()
            if result == false then handlers[identifier] = nil end
        end

        instance:RemoveIfEmpty(handlers, eventId)
    end
end

function EventManager:RemoveIfEmpty(handlers, eventId)
    if not next(handlers) then
        local eventRegistrar = events[eventId]
        if eventRegistrar then
            eventRegistrar(nil)
        else
            events.register(eventId, nil)
        end
    end
end

function EventManager:Enter(eventName, eventId, identifier)
    self.Active = {{eventName, eventId, identifier}, self.Active}
end

function EventManager:Leave() self.Active = self.Active[2] end

function EventManager:SetHandler(eventId, handler, identifier)
    if not self.Handlers then self.Handlers = {} end
    if not identifier then identifier = "default" end

    local eventName = type(eventId) == "number" and self.EventDefinesByIndex[eventId] or eventId

    local handlers = self.Handlers[eventName]
    assert(not handlers or identifier ~= "default") -- handler for event already registered. Use identifier

    if not handlers then
        handlers = {}
        self.Handlers[eventName] = handlers

        local watchedEvent = self:Execute(eventId, eventName)
        local eventRegistrar = events[eventId]
        if eventRegistrar then
            eventRegistrar(watchedEvent)
        else
            events.register(eventId, watchedEvent)
        end
    end

    assert(not handlers[identifier] or handlers[identifier] == handler or handler == nil) -- another handler with the same identifier is already installed for that event

    handlers[identifier] = handler

    self:RemoveIfEmpty(handlers, eventId)
end

return EventManager

