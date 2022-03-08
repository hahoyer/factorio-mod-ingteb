local Constants = require "Constants"
local class = require "core.class"
local Table = require "core.Table"
local Array = Table.Array
local sonaxaton = require "core.Sonaxaton"

local Class = class:new(
    "ResearchQueue", nil, {
        Force = {get = function(self) return self.Parent.Player.force end},
        Current = {
            get = function(self)
                if sonaxaton.IsValid() then
                    return Array:new(sonaxaton.GetQueue(self.Force))
                end
                return Array --
                :new(self.Force.research_queue) --
                :Select(function(technology) return technology.name end)
            end,
        },
    }
)

function Class:new(parent)
    local result = self:adopt{Parent = parent}
    return result
end

function Class:IsResearching(name)
    local queue = self.Current
    for index = 1, #queue do if queue[index] == name then return true end end
end

function Class:SonaxatonCheck()
    if sonaxaton.IsValid() then return end
    if script.active_mods["sonaxaton-research-queue"] == nil then return end

    for _, player in pairs(self.Force.players) do
        player.print {
            "",
            "[color=yellow]",
            {"ingteb-utility.research-not-available", {"mod-name.sonaxaton-research-queue"}},
            "[/color]",
        }
        player.print {
            "ingteb-utility.remark-style",
            {
                "ingteb-utility.research-not-available-alternative",
                {"mod-name.sonaxaton-research-queue"},
                {
                    "",
                    "[font=default-large-bold][color=blue]",
                    "'sonaxaton-research-queue-with-interface'",
                    "[/color][/font]",
                },
            },

        }
    end

end

function Class:AddResearch(name, setting)
    if setting == "off" then return end
    if sonaxaton.IsValid() then
        sonaxaton.Enqueue(self.Force, name)
        return true
    end

    if #self.Force.research_queue == 0 --
    or self.Force.research_queue_enabled and setting ~= "1" then
        return self.Force.add_research(name)
    end

    self:SonaxatonCheck()
end

return Class
