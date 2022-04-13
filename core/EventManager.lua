local events = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")

-- __DebugAdapter.breakpoint(mesg:LocalisedString)
local Class = class:new("core.EventManager")

Class.system.Abstract = true

Class.system.Properties = {
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
                    dassert()
                end

                if game then UI.Player = game.players[UI.PlayerIndex] end

            else
                dassert()
                UI.Player = nil
                UI.PlayerIndex = nil
            end

            dassert(lastPlayerIndex == nil or lastPlayerIndex == UI.PlayerIndex)
            dassert(lastPlayer == nil or lastPlayer == UI.Player)
        end,
    },
    Global = {get = function(self) return global.Players[UI.PlayerIndex] end},
}

Class.EventDefinesByIndex = Dictionary:new(defines.events) --
:ToDictionary(function(value, key) return {Key = value, Value = key} end) --
:ToArray()

function Class:Execute(eventId, eventName)
    return function(...)
        local handlers = self.Handlers[eventName]
        for identifier, handler in pairs(handlers) do
            self:Enter(eventName, eventId, identifier)
            local result = handler.Handler(handler.Instance, ...)
            self:Leave()
            if result == false then handlers[identifier] = nil end
        end

        self:RemoveIfEmpty(handlers, eventId)
    end
end

function Class:RemoveIfEmpty(handlers, eventId)
    if not next(handlers) then
        local eventRegistrar = events[eventId]
        if eventRegistrar then
            eventRegistrar(nil)
        else
            events.register(eventId, nil)
        end
    end
end

function FormatData(data)
    return tostring(data[1]) .. "/" .. tostring(data[2]) .. "/" .. tostring(data[3])
end

function Class:Enter(eventName, eventId, identifier)
    local data = {eventName, eventId, identifier}
    --ilog(">>>EnterEvent " .. FormatData(data))
    local oldIndent = nil --AddIndent()
    self.Active = {data, self.Active, oldIndent}
end

function Class:Leave()
    --indent = self.Active[3]
    --ilog("<<<LeaveEvent " .. FormatData(self.Active[1]))
    self.Active = self.Active[2]
end

---comment
---@param eventId any a number or string that identifies the event
---@param handler function a function with self as first argument and more arguments according to eventId. If function returns false the handler is removed after execution
---@param identifier string a name that identifies the event registration. Has to be set if you need more than one handler for an event. Must not be "default" to achieve this.
function Class:SetHandler(eventId, handler, identifier)
    if not Class.Handlers then Class.Handlers = {} end
    if not identifier then identifier = "default" end

    local eventName = --
    type(eventId) == "number" and Class.EventDefinesByIndex[eventId] or --
    eventId == 0 and "on_tick" or --
    eventId

    local handlers = Class.Handlers[eventName]
    dassert(
        not handlers or identifier ~= "default",
            "handler for event " .. eventName .. " already registered. Use identifier"
    )

    if not handlers then
        handlers = {}
        Class.Handlers[eventName] = handlers

        local watchedEvent = Class:Execute(eventId, eventName)
        local eventRegistrar = events[eventId]
        if eventRegistrar then
            eventRegistrar(watchedEvent)
        else
            events.register(eventId, watchedEvent)
        end
    end

    dassert(not handlers[identifier] or handlers[identifier] == handler or handler == nil) -- another handler with the same identifier is already installed for that event

    handlers[identifier] = {Instance = self, Handler = handler}

    Class:RemoveIfEmpty(handlers, eventId)
end

return Class

