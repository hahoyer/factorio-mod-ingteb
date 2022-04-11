local gui = require("__flib__.gui-beta")
local translation = require("__flib__.translation")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local UI = require("core.UI")

local Class = class:new(
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
                return type(self.Translation.Name) == "string" and self.Translation.Name or self.Name
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
                if self.HasDescription then
                    result:Append(self.LocalizedDescription)
                elseif self.Entity and self.Entity.HasDescription then
                    result:Append(self.Entity.LocalizedDescription)
                end
                result:AppendMany(self.ComponentHelp)
                result:AppendMany(self.ProductHelp)
                return result
            end,
        },

        ComponentHelp = {
            get = function(self)
                if not self.Input then return {} end
                local result = Array:new{
                    {
                        "",
                        "[font=heading-1][color=#F8E1BC]",
                        {"description.ingredients"},
                        ":[/color][/font]",
                    },

                }
                result:AppendMany(
                    self.Input:Select(
                        function(stack)
                            return {
                                "",
                                stack.HelpTextWhenUsedAsProduct,
                                self.Database:GetItemsPerTickText(stack.Amounts, self.Time),
                            }
                        end
                    )
                )

                if self.Time then
                    result:Append{
                        "",
                        "[img=utility/clock][font=default-bold]" .. self.Time .. " s[/font] ",
                        {"description.crafting-time"},
                        self.Database:GetItemsPerTickText({value = 1}, self.Time),
                    }
                end

                return result

            end,
        },

        ProductHelp = {
            get = function(self)
                if not self.Output or --
                self.Output:Count() == 1 and self.Output[1].Amounts.value == 1
                    and self.Output[1].Amounts.catalyst_amount == nil --
                then return {} end

                local result = Array:new{
                    {
                        "",
                        "[font=heading-1][color=#F8E1BC]",
                        {"description.products"},
                        ":[/color][/font]",
                    },

                }
                result:AppendMany(
                    self.Output:Select(
                        function(stack)
                            return {
                                "",
                                stack.HelpTextWhenUsedAsProduct,
                                self.Database:GetItemsPerTickText(stack.Amounts, self.Time),
                            }
                        end
                    )
                )

                return result
            end,
        },

        Output = {
            cache = true,
            get = function(self)
                if self.RawOutput then
                    return Array:new(self.RawOutput) --
                    :Select(
                        function(product, index)
                            local result = self.Database:GetStackOfGoods(product)
                            if result then
                                result.Source = {Recipe = self, ProductIndex = index}
                            else
                                self.IsHidden = true
                            end
                            return result
                        end
                    ) --
                    :Where(function(value) return value end) --
                end
            end,
        },
        Input = {
            cache = true,
            get = function(self)
                if self.RawInput then
                    return Array:new(self.RawInput) --
                    :Select(
                        function(ingredient, index)
                            if ingredient.type == "resource" then
                                return ingredient.value
                            else
                                local result = self.Database:GetStackOfGoods(ingredient)
                                if result then
                                    result.Source = {Recipe = self, IngredientIndex = index}
                                else
                                    self.IsHidden = true
                                end
                                return result
                            end
                        end
                    ) --
                    :Where(
                        function(value)
                            return not (value.flags and value.flags.hidden)
                        end
                    ) --
                end
            end,
        },

        SpriteName = {
            cache = true,
            get = function(self)
                local spriteType = self.SpriteType or self.Prototype.type
                return spriteType .. "/" .. self.Prototype.name
            end,
        },

        RichTextName = {get = function(self) return "[img=" .. self.SpriteName .. "]" end},
        HelperHeaderText = {get = function(self) return self.LocalisedName end},

    }
)

function Class:CreatePrototype(type, name)
    return {
        type = type,
        name = name,
        localised_name = {"ingteb-name." .. type .. "-" .. name},
        localised_description = {"ingteb-descrition." .. type .. "-" .. name},
    }
end

function Class:IsBefore(other)
    if self == other then return false end
    if self.TypeOrder ~= other.TypeOrder then return self.TypeOrder < other.TypeOrder end
    if self.TypeSubOrder ~= other.TypeSubOrder then return self.TypeSubOrder < other.TypeSubOrder end
    if self.Group.order ~= other.Group.order then return self.Group.order < other.Group.order end
    if self.SubGroup.order ~= other.SubGroup.order then
        return self.SubGroup.order < other.SubGroup.order
    end
    return self.Prototype.order < other.Prototype.order
end

function Class:Clone() return self.Database:GetProxyFromCommonKey(self.CommonKey) end

function Class:GetHandCraftingRequest(event) end
function Class:GetResearchRequest(event) end

function Class:GetSpecialFunctions(site)
    local lines = Dictionary:new{}
    self.SpecialFunctions --
    :Select(
        function(specialFunction)
            if --
            (not specialFunction.IsRestricedTo or specialFunction.IsRestricedTo[site]) --        
                and (not specialFunction.IsAvailable or specialFunction.IsAvailable(self)) then
                local key = specialFunction.UICode
                if (not lines[key]) then lines[key] = specialFunction end
            end --
        end
    )
    return lines:ToArray()
end

function Class:GetFunctionalHelp(site)
    return self:GetSpecialFunctions(site) --
    :Where(function(specialFunction) return specialFunction.HelpText end) --
    :Select(
        function(specialFunction)
            return UI.GetHelpTextForButtons({specialFunction.HelpText}, specialFunction.UICode)
        end
    ) --
    :ToArray()
end

function Class:GetHelperText(site)
    local name = {"", "[font=default-large-bold]", self.HelperHeaderText, "[/font]"}
    -- append(self.LocalizedDescription)
    local additionalHelp = self.AdditionalHelp
    local functionalHelp = self:GetFunctionalHelp(site)

    return Helper.ConcatLocalisedText(name, additionalHelp:Concat(functionalHelp))
end

function Class:AssertValid()
    if self.IsRecipe and not self.Workers:Any() then
        local prototype = self.Prototype
        log {
            "mod-issue.missing-worker",
            prototype.localised_name,
            prototype.object_name .. "." .. prototype.name,
        }
    end
end

function Class:SealUp()
    self.CommonKey = self.class.name .. "." .. self.Name
    self.Database:EnsureUsage(self, self.RawInput, self.RawOutput)
    self:SortAll()

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

function Class:GetNumberOnSprite(category) end

function Class:GetAction(event)
    local message = gui.read_action(event)
    local specialFunction = self:GetSpecialFunctions(message.module) --
    :Where(function(specialFunction) return UI.IsMouseCode(event, specialFunction.UICode) end) --
    :Top(nil, false)

    if specialFunction then return specialFunction.Action(self, event) end
end

function Class:new(prototype, database)
    dassert(prototype)
    dassert(database)

    if __DebugAdapter then self.CommonKey = "?pending" end -- required for debugging 
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

return Class
