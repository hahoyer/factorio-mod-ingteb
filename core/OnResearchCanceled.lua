local events = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")
local core = {EventManager = require "core.EventManager"}

local Class = class:new("core.OnResearchCanceled", core.EventManager)

defines.events.on_research_canceled = script.generate_event_name()
Class.EventId = defines.events.on_research_canceled

function Class:GetResearchQueue(force)
    return Array:new(force.research_queue):Select(function(technology) return technology.name end)
end

function Class:HasResearchQueueChanged(force)
    local last = self.Forces[force.index]
    if #last ~= #force.research_queue then return true end
    for index = 1, #last do
        if last[index] ~= force.research_queue[index].name then return true end
    end
end

function Class:AlignResearchQueueCopy(force)
    if self.Forces[force.index] then
        if not self:HasResearchQueueChanged(force) then return end

        local active = Array:new(force.research_queue) --
        :ToDictionary(function(technology) return {Key = technology.name, Value = true} end)

        self.Forces[force.index] --
        :Where(function(name) return not active[name] end) --
        :Select(
            function(name)
                script.raise_event(
                    defines.events.on_research_canceled, {research = force.technologies[name]}
                )
            end
        )
    end
    self:RefreshResearchQueueCopy(force)
end

function Class:RefreshResearchQueueCopy(force)
    self.Forces[force.index] = self:GetResearchQueue(force)
end

function Class:OnTick(event)
    if self.NextTickToCheck and self.NextTickToCheck > event.tick then return end
    self.NextTickToCheck = event.tick + 60

    for _, force in pairs(game.forces) do self:AlignResearchQueueCopy(force) end
end

function Class:OnResearchChanged(event) self:RefreshResearchQueueCopy(event.research.force) end

function Class:RefreshResearchQueueCopies()
    for _, force in pairs(game.forces) do self:RefreshResearchQueueCopy(force) end
end

function Class:new()
    local self = self:adopt{Forces = {}}

    self:SetHandler(defines.events.on_research_finished, self.OnResearchChanged, self.class.name)
    self:SetHandler(defines.events.on_research_started, self.OnResearchChanged, self.class.name)
    self:SetHandler(defines.events.on_tick, self.OnTick, self.class.name)
    return self
end

return Class

