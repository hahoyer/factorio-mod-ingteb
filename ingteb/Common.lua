local gui = require "__flib__.gui"
local localisation = require "__flib__.dictionary"
local Constants = require("Constants")
local Configurations = require("Configurations").Database
local Helper = require("ingteb.Helper")

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local class = require("core.class")
local UI = require("core.UI")

local gameKeyFromObjectName = {
    LuaRecipeCategoryPrototype = "recipe_category_prototypes",
    LuaEntityPrototype = "entity_prototypes",
    LuaFuelCategoryPrototype = "fuel_category_prototypes",
    LuaResourceCategoryPrototype = "resource_category_prototypes",
    LuaTechnologyPrototype = "technology_prototypes",
    LuaRecipePrototype = "recipe_prototypes",
    LuaItemPrototype = "item_prototypes",
    LuaFluidPrototype = "fluid_prototypes",
    LuaModuleCategoryPrototype = "module_category_prototypes",
}

local Class = class:new(
    "Common", nil, {
    Player = { get = function(self) return self.Database.Player end },
    DebugLine = { get = function(self) return self.CommonKey end },
    ClickTarget = { cache = true, get = function(self) return self.CommonKey end },
    Group = { cache = true, get = function(self) return self.Prototype.group end },
    SubGroup = { cache = true, get = function(self) return self.Prototype.subgroup end },
    BackLinkName = { get = function(self) return self.Name end },
    BackLinkType = {},
    BackLinks = { get = function(self) return self.Database.Game[self.BackLinkType][self.BackLinkName] end, },
    NoPrototype = {
        cache = true,
        get = function(self)
            local realm = self.PrototypeData.Realm
            if realm == "game" then
                return game[self.PrototypeData.Group][self.PrototypeData.Name]
            elseif realm == "constant" then
                return self.PrototypeData.Value
            else
                dassert(false, "invalid realm: " .. realm)
            end
        end,
    },
    GameKeyForLocalisation = {
        get = function(self)
            local object_name = self.Prototype.object_name or self.Prototype.object_name_prototype
            return gameKeyFromObjectName[object_name]
        end,
    },

    TypeOrder = {
        cache = true,
        get = function(self) return Configurations.Order[self.class.name] end,
    },

    LocalisedName = {
        get = function(self)
            local type = self.TypeStringForLocalisation
            local name = self.Prototype.localised_name
            if not self.TranslatedName then name = "[" .. self.Name .. "]" end

            if type then
                return { "", name, " (", { type }, ")" }
            else
                return name
            end
        end,
    },

    LocalizedDescription = {
        get = function(self)
            return { "ingteb-utility.remark-style", self.Prototype.localised_description, }
        end
    },

    TranslatedName = { --
        get = function(self)
            local gameKey = self.GameKeyForLocalisation
            if gameKey then
                return self.Database:GetTranslation(gameKey, self.Name, "Names")
            else
                return true
            end
        end,
    },

    TranslatedDescription = {
        get = function(self)
            local gameKey = self.GameKeyForLocalisation
            if gameKey then
                return self.Database:GetTranslation(self.GameKeyForLocalisation, self.Name, "Descriptions")
            else
                return true
            end
        end,
    },

    SearchText = {
        get = function(self)
            return self.TranslatedName or self.Name
        end,
    },

    SpecialFunctions = {
        get = function(self)
            return Array:new { --
                {
                    UICode = "--- l", --
                    Action = function(self) return { Presenting = self } end,
                },
            }

        end,
    },

    AdditionalHelp = {
        get = function(self)
            local result = Array:new {}
            if self.TranslatedDescription then
                result:Append(self.LocalizedDescription)
            elseif self.Entity and self.Entity.TranslatedDescription then
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
            local result = Array:new {
                {
                    "",
                    "[font=heading-1][color=#F8E1BC]",
                    { "description.ingredients" },
                    ":[/color][/font]",
                },

            }
            result:AppendMany(
                self.Input:Select(
                    function(stack)
                        return {
                            "",
                            stack.HelpTextWhenUsedAsProduct,
                            self.Database:GetItemsPerTickText(stack.Amounts, self.RelativeDuration),
                        }
                    end
                )
            )

            if self.RelativeDuration then
                result:Append {
                    "",
                    "[img=utility/clock][font=default-bold]" .. self.RelativeDuration .. " s[/font] ",
                    { "description.crafting-time" },
                    self.Database:GetItemsPerTickText({ value = 1 }, self.RelativeDuration),
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

            local result = Array:new {
                {
                    "",
                    "[font=heading-1][color=#F8E1BC]",
                    { "description.products" },
                    ":[/color][/font]",
                },

            }
            result:AppendMany(
                self.Output:Select(
                    function(stack)
                        return {
                            "",
                            stack.HelpTextWhenUsedAsProduct,
                            self.Database:GetItemsPerTickText(stack.Amounts, self.RelativeDuration),
                        }
                    end
                )
            )

            return result
        end,
    },

    SpriteType = { get = function(self) return self.Prototype.type end },

    SpriteName = {
        cache = true,
        get = function(self)
            local spriteType = self.SpriteType
            return spriteType .. "/" .. self.Prototype.name
        end,
    },

    RichTextName = { get = function(self) return "[img=" .. self.SpriteName .. "]" end },
    HelperHeaderText = { get = function(self) return self.LocalisedName end },

}
)

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

function Class:GetBackLinkArray(propertyName, typeName)
    local variants = self.BackLinks[Helper.GetNestedPath(propertyName)]
    if not variants then return Array:new() end
    dassert(typeName, "typeName can be " .. next(variants) .. ".")
    local proxies = variants[typeName]
    if not proxies then return Array:new() end
    local xreturn = Dictionary
        :new(proxies)
        :ToArray(function(_, name) return self.Database:GetFromBackLink { Type = typeName, Name = name } end)
    return xreturn
end

function Class:Clone() return self.Database:GetProxyFromCommonKey(self.CommonKey) end

function Class:GetHandCraftingRequest(event) end

function Class:GetResearchRequest(event) end

function Class:GetSpecialFunctions(site)
    local lines = Dictionary:new {}
    self.SpecialFunctions--
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
    return self:GetSpecialFunctions(site)--
        :Where(function(specialFunction) return specialFunction.HelpTextTag end)--
        :Select(
            function(specialFunction)
                local text = specialFunction.HelpTextItems or {}
                table.insert(text, 1, specialFunction.HelpTextTag)
                local xreturn = UI.GetHelpTextForButtons(text, specialFunction.UICode)
                return xreturn
            end
        )--
        :ToArray()
end

function Class:GetHelperText(site)
    local name = { "", "[font=default-large-bold]", self.HelperHeaderText, "[/font]" }
    -- append(self.LocalizedDescription)
    local additionalHelp = self.AdditionalHelp
    local functionalHelp = self:GetFunctionalHelp(site)

    return Helper.ConcatLocalisedText(name, additionalHelp:Concat(functionalHelp))
end

function Class:AssertValid()
    if self.IsRecipe then
        if not self.Workers:Any() then
            local prototype = self.Prototype
            log {
                "mod-issue.missing-worker",
                prototype.localised_name,
                (prototype.object_name or prototype.type) .. "." .. prototype.name,
            }
        end
        dassert(type(self.RelativeDuration) == "number")
        if self.class.name == "Recipe" then
            dassert(self.Category.Domain == "Crafting")
        else
            dassert(self.Category.Domain ~= "Crafting")
        end
    end

    local category = self.Category
    if false and category and category.Domain == "Burning" then
        local prototype = self.Prototype
        dlog(self.Name)
        local indent = AddIndent()
        dlog("fuel_value = " .. prototype.fuel_value)
        dlog("category = " .. category.Name)
        dlog("category.SpeedFactor = " .. category.SpeedFactor)

        self.Workers:Select(function(worker)
            dlog(worker.Name)
            local indent = AddIndent()
            dlog("SpeedFactor = " .. worker:GetSpeedFactor(category))
            ResetIndent(indent)
        end)

        ResetIndent(indent)
    end

end

function Class:SealUp()
    self.CommonKey = self.class.name .. "." .. self.Name
    self:SortAll()
    self.IsSealed = true
    self:AssertValid()
    return self
end

function Class:GetNumberOnSprite(category) end

function Class:GetAction(event)
    local message = gui.read_action(event)
    local specialFunction = self:GetSpecialFunctions(message.module)--
        :Where(function(specialFunction) return UI.IsMouseCode(event, specialFunction.UICode) end)--
        :Top(nil, false)

    if specialFunction then return specialFunction.Action(self, event) end
end

function Class:SplitPrototype(prototype)
    local objectName = prototype.object_name
    if objectName then
        local key = gameKeyFromObjectName[prototype.object_name]
        if key then
            return { Realm = "game", Group = key, Name = prototype.name }
        else
            dassert(
                false, "Unexpected protptype: " .. type(prototype) .. " " .. prototype.object_name
            )
        end
    else
        dassert(prototype.type)
        dassert(prototype.name)
        dassert(prototype.localised_name)
        dassert(prototype.localised_description)
        return { Realm = "constant", Value = prototype }
    end
end

function Class:new(prototype, database)
    dassert(prototype)
    dassert(database)

    local filterdPrototype
    if __DebugAdapter then
        self.CommonKey = "?pending" -- required for debugging
        filterdPrototype = database:GetFilteredProxy(prototype)
    end

    local self = self:adopt {
        Prototype = prototype,
        Database = database,
        FilterdPrototype = filterdPrototype
    }
    self.IsSealed = false
    self.Name = self.Prototype.name
    self.TypeSubOrder = 0

    return self

end

return Class
