local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")

local Common = class:new("Common")

Common.property = {
    ClickTarget = {cache = true, get = function(self) return self.CommonKey end},
    Group = {cache = true, get = function(self) return self.Prototype.group end},
    SubGroup = {cache = true, get = function(self) return self.Prototype.subgroup end},
    TypeOrder = {cache = true, get = function(self) return self.Database.Order[self.class.name] end},

    LocalisedName = {
        get = function(self)
            return {
                "gui-text-tags.following-text-" .. (self.TypeForLocalisation or self.SpriteType),
                self.Prototype.localised_name,
            }
        end,
    },

    SpecialFunctions = {
        get = function(self)
            return Array:new{ --
                {
                    UICode = "--- l", --
                    Action = function(self) return {Presenting = self} end,
                },
            }

        end,
    },

    AdditionalHelp = {get = function(self) return Array:new{} end},
    HasLocalisedDescription = {get = function() end},

    SpriteName = {
        cache = true,
        get = function(self) return self.SpriteType .. "/" .. self.Prototype.name end,
    },

    RichTextName = {get = function(self) return "[img=" .. self.SpriteName .. "]" end},
}

function Common:IsBefore(other)
    if self == other then return false end
    if self.TypeOrder ~= other.TypeOrder then return self.TypeOrder < other.TypeOrder end
    if self.TypeSubOrder ~= other.TypeSubOrder then return self.TypeSubOrder < other.TypeSubOrder end
    if self.Group.order ~= other.Group.order then return self.Group.order < other.Group.order end
    if self.SubGroup.order ~= other.SubGroup.order then return self.SubGroup.order < other.SubGroup.order end
    return self.Prototype.order < other.Prototype.order
end

function Common:GetHandCraftingRequest(event) end
function Common:GetResearchRequest(event) end

function Common:GetFunctionalHelp(site)
    return self.SpecialFunctions --
    :Select(
        function(specialFunction)
            return --
            (not specialFunction.IsRestricedTo or specialFunction.IsRestricedTo[site]) --        
                and (not specialFunction.IsAvailable or specialFunction.IsAvailable(self)) --
                and specialFunction.HelpText --
                and UI.GetHelpTextForButtons(specialFunction.HelpText, specialFunction.UICode) or nil
        end
    )
end

function Common:GetHelperText(site)

    local name = self.LocalisedName
    local lines = Array:new{}
    local function append(line)
        if line then
            lines:Append("\n")
            lines:Append(line)
        end
    end
    -- append(self.LocalizedDescription)
    local additionalHelp = self.AdditionalHelp
    local functionalHelp = self:GetFunctionalHelp(site)
    additionalHelp:Select(append)
    functionalHelp:Select(append)
    if lines:Any() then
        lines:InsertAt(1, "")
        return {"", name, lines}
    end
    return name
end

function Common:SealUp()
    self:SortAll()
    self.CommonKey = self.class.name .. "." .. self.Name 
    return self
end

function Common:GetAction(event)
    for _, specialFunction in pairs(self.SpecialFunctions) do
        if UI.IsMouseCode(event, specialFunction.UICode) then
            if (not specialFunction.IsAvailable or specialFunction.IsAvailable(self)) then
                return specialFunction.Action(self, event)
            end
        end
    end
end

function Common:new(prototype, database)
    assert(release or prototype)
    assert(release or database)

    local self = self:adopt{Prototype = prototype, Database = database}
    self.Name = self.Prototype.name
    self.TypeSubOrder = 0
    self.LocalizedDescription = self.Prototype.localised_description

    return self

end

return Common
