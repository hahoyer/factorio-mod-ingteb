local translation = require("__flib__.translation")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")

local Common = class:new(
    "Common", nil, {
        DebugLine = {get = function(self) return self.CommonKey end},
        ClickTarget = {cache = true, get = function(self) return self.CommonKey end},
        Group = {cache = true, get = function(self) return self.Prototype.group end},
        SubGroup = {cache = true, get = function(self) return self.Prototype.subgroup end},
        TypeOrder = {
            cache = true,
            get = function(self) return self.Database.Order[self.class.name] end,
        },

        LocalisedName = {
            get = function(self)
                local type = self.TypeStringForLocalisation
                local name = self.Prototype.localised_name
                if self.Translation.Name == false then name = "[" .. self.Name .. "]" end

                if type then
                    return {"", name, " (", {type}, ")"}
                else
                    return name
                end
            end,
        },

        HasDescription = {
            get = function(self) return type(self.Translation.Description) == "string" end,
        },

        SearchText = {
            get = function(self)
                return
                    type(self.Translation.Name) == "string" and self.Translation.Name or self.Name
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

        AdditionalHelp = {
            get = function(self)
                local result = Array:new{}
                if self.HasDescription then result:Append(self.LocalizedDescription) end
                return result
            end,
        },

        SpriteName = {
            cache = true,
            get = function(self) return self.SpriteType .. "/" .. self.Prototype.name end,
        },

        RichTextName = {get = function(self) return "[img=" .. self.SpriteName .. "]" end},
        HelperHeaderText = {get = function(self) return self.LocalisedName end},

    }
)

function Common:IsBefore(other)
    if self == other then return false end
    if self.TypeOrder ~= other.TypeOrder then return self.TypeOrder < other.TypeOrder end
    if self.TypeSubOrder ~= other.TypeSubOrder then return self.TypeSubOrder < other.TypeSubOrder end
    if self.Group.order ~= other.Group.order then return self.Group.order < other.Group.order end
    if self.SubGroup.order ~= other.SubGroup.order then
        return self.SubGroup.order < other.SubGroup.order
    end
    return self.Prototype.order < other.Prototype.order
end

function Common:Clone() return self.Database:GetProxyFromCommonKey(self.CommonKey) end

function Common:GetHandCraftingRequest(event) end
function Common:GetResearchRequest(event) end

function Common:GetFunctionalHelp(site)
    local lines = Dictionary:new{}
    self.SpecialFunctions --
    :Select(
        function(specialFunction)
            if --
            (not specialFunction.IsRestricedTo or specialFunction.IsRestricedTo[site]) --        
                and (not specialFunction.IsAvailable or specialFunction.IsAvailable(self)) --
                and specialFunction.HelpText then
                local key = specialFunction.UICode
                if not lines[key] then
                    lines[key] = UI.GetHelpTextForButtons(
                        specialFunction.HelpText, specialFunction.UICode
                    )
                end
            end --
        end
    )
    return lines:ToArray()
end

function Common:GetHelperText(site)
    local name = {"", "[font=default-large-bold]", self.HelperHeaderText, "[/font]"}
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
        return {"", name, Helper.ScrutinizeLocalisationString(lines)}
    end
    return name
end

function Common:AssertValid() end

function Common:SealUp()
    self:SortAll()
    self.CommonKey = self.class.name .. "." .. self.Name

    translation.add_requests(
        self.Database.Player.index, {
            {
                dictionary = "Description",
                internal = self.CommonKey,
                localised = self.Prototype.localised_description,
            },
            {
                dictionary = "Name",
                internal = self.CommonKey,
                localised = self.Prototype.localised_name,
            },
        }
    )
    self:AssertValid()
    self.IsSealed = true
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
    dassert(prototype)
    dassert(database)

    local self = self:adopt{Prototype = prototype, Database = database}
    self.IsSealed = false
    self.Name = self.Prototype.name
    self.TypeSubOrder = 0
    self.LocalizedDescription = {
        "ingteb-utility.remark-style",
        self.Prototype.localised_description,
    }
    self.Translation = {}

    return self

end

return Common
