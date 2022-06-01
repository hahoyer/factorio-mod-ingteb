local migration = require "__flib__.migration"
local MetaDataScan = require "ingteb.MetaDataScan"
local CoreHelper = require "core.Helper"
local Number = require("core.Number")
local Constants = require("Constants")
local Configurations = require("Configurations").Database
local Helper = require "ingteb.Helper"

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local class = require("core.class")
local TimeSpan = require("core.TimeSpan")
local StackOfGoods = require("ingteb.StackOfGoods")
local RecipeCommon = require("ingteb.RecipeCommon")

local Proxy = {
    Bonus = require("ingteb.Bonus"),
    BurningRecipe = RecipeCommon.BurningRecipe,
    Category = require("ingteb.Category"),
    Entity = require("ingteb.Entity"),
    Fluid = require("ingteb.Fluid"),
    FluidBurningRecipe = RecipeCommon.FluidBurningRecipe,
    FluidMiningRecipe = RecipeCommon.FluidMiningRecipe,
    FuelCategory = require("ingteb.FuelCategory"),
    HandMiningRecipe = RecipeCommon.HandMiningRecipe,
    Item = require("ingteb.Item"),
    MiningRecipe = RecipeCommon.MiningRecipe,
    ModuleCategory = require("ingteb.ModuleCategory"),
    ModuleEffect = require("ingteb.ModuleEffect"),
    Recipe = require("ingteb.Recipe"),
    RocketLaunchRecipe = RecipeCommon.RocketLaunchRecipe,
    Technology = require("ingteb.Technology"),
}

local Class = class:new(
    "Database", nil, {
    Player = { get = function(self) return self.Parent.Player end },
    PlayerGlobal = { get = function(self) return self.Parent.PlayerGlobal end },
    Game = { get = function(self) return global.Game end },
    BackLinks = {},
    ProductionTimeUnit = {
        get = function(self)
            local rawValue = settings.get_player_settings(self.Player)["ingteb_production-timeunit"]
                .value
            return TimeSpan.FromString(rawValue) or Constants.ProductionTimeUnit
        end,
    },
    Selector = {
        cache = true,
        get = function(self)
            log("database initialize Selector...")
            local result = {}
            local maximumColumnCount = 0
            result.Groups = Dictionary:new {}
            local targets = {
                Item = game.item_prototypes,
                Fluid = game.fluid_prototypes,
                FuelCategory = game.fuel_category_prototypes,
                ModuleCategory = game.module_category_prototypes,
            }

            local function IsHidden(type, goods)
                if type == "Item" then
                    return goods.flags and goods.flags.hidden
                elseif type == "Fluid" then
                    return goods.hidden
                end
            end

            for type, domain in pairs(targets) do
                for name, goods in pairs(domain) do
                    if not IsHidden(type, goods) then
                        local grouping = --
                        (type == "Item" or type == "Fluid")
                            and { goods.group.name, goods.subgroup.name } --
                            or { "other", type }

                        local group = CoreHelper.EnsureKey(result.Groups, grouping[1], Dictionary:new {})
                        local subgroup = CoreHelper.EnsureKey(group, grouping[2], Array:new {})
                        subgroup:Append(self:GetProxy(type, nil, goods))
                        if maximumColumnCount < subgroup:Count() then
                            maximumColumnCount = subgroup:Count()
                        end
                    end
                end
            end
            result.ColumnCount = maximumColumnCount < Constants.SelectorColumnCount
                and maximumColumnCount or result.Groups:Count() * 2
            log("database initialize Selector complete.")
            return result
        end,
    },
}
)

function Class:new(parent)
    local self = self:adopt
    {
        Parent = parent,
        Proxies = {},
        ClassNameFromGameType = {
            item = "Item",
            entity = "Entity",
            technology = "Technology",
            recipe = "Recipe",
        }
    }

    Dictionary:new(Configurations.RecipeDomains)
        :Select(function(setup)
            if self.ClassNameFromGameType[setup.Recipe.GameType] then
                dassert(self.ClassNameFromGameType[setup.Recipe.GameType] == setup.Recipe.ClassName)
            elseif setup.Recipe.ClassName then
                self.ClassNameFromGameType[setup.Recipe.GameType] = setup.Recipe.ClassName
            end
        end)

    return self
end

function Class:GetItemsPerTickText(amounts, ticks)
    if not amounts or not ticks then return "" end
    local amount = amounts.value or (amounts.max + amounts.min) / 2
    return " ("
        .. Number:new(self.ProductionTimeUnit:getTicks() * amount / ticks).Format3Digits
        .. "[img=items-per-timeunit]" .. ")"
end

function Class:GetProxyFromCommonKey(targetKey)
    local _, _, className, prototypeName = targetKey:find("^(.-)%.(.*)$")
    local result = self:GetProxy(className, prototypeName)
    return result
end

function Class:GetProxyFromPrototype(prototype)
    local objectType = prototype.object_name or prototype.type
    if objectType == "LuaFluidPrototype" then
        return self:GetFluid(nil, prototype)
    elseif objectType == "LuaItemPrototype" then
        return self:GetItem(nil, prototype)
    elseif objectType == "LuaEntityPrototype" then
        return self:GetEntity(nil, prototype)
    elseif objectType == "LuaRecipePrototype" then
        return self:GetRecipe(nil, prototype)
    elseif objectType == "Burning" or objectType == "fluid_burning" then
        return self:GetBurningRecipe(nil, prototype)
    elseif objectType == "Boiling" then
        return self:GetBoilingRecipe(nil, prototype)
    elseif objectType == "Mining" or objectType == "hand_mining" or objectType == "FluidMining" then
        return self:GetMiningRecipe(nil, prototype)
    elseif objectType == "rocket_launch" then
        return self:GetRocketLaunchRecipe(nil, prototype)
    else
        dassert(false)
    end
end

function Class:GetProxy(className, name, prototype)
    local data = CoreHelper.EnsureKey(self.Proxies, className, Dictionary:new())
    local key = name or prototype.name

    local result = data[key]
    dassert(result ~= "pending")

    if result then return result end
    if result == false then return end

    data[key] = "pending"
    result = Proxy[className]:new(name, prototype, self)
    data[key] = result or false
    if result then
        result:SealUp()
    end
    return result
end

function Class:GetFluid(name, prototype) return self:GetProxy("Fluid", name, prototype) end

function Class:GetItem(name, prototype) return self:GetProxy("Item", name, prototype) end

function Class:GetEntity(name, prototype) return self:GetProxy("Entity", name, prototype) end

function Class:GetCategory(name, prototype) return self:GetProxy("Category", name, prototype) end

function Class:GetRecipe(name, prototype) return self:GetProxy("Recipe", name, prototype) end

function Class:GetTechnology(name, prototype) return self:GetProxy("Technology", name, prototype) end

function Class:GetModuleCategory(name, prototype) --
    return self:GetProxy("ModuleCategory", name, prototype)
end

function Class:GetModuleEffect(name, prototype) --
    return self:GetProxy("ModuleEffect", name, prototype)
end

function Class:GetMiningRecipe(name, prototype) --
    dassert(not name)
    return self:GetProxy("MiningRecipe", name, prototype)
end

function Class:GetBoilingRecipe(name, prototype) --
    dassert(not name)
    return self:GetProxy("BoilingRecipe", name, prototype)
end

function Class:GetBurningRecipe(name, prototype) --
    dassert(not name)
    return self:GetProxy("BurningRecipe", name, prototype)
end

function Class:GetRocketLaunchRecipe(name, prototype) --
    dassert(not name)
    return self:GetProxy("RocketLaunchRecipe", name, prototype)
end

function Class:GetFuelCategory(name, prototype) --
    return self:GetProxy("FuelCategory", name, prototype)
end

function Class:GetFuelCategories()
    return Dictionary:new(self.BackLinks.EntitiesForBurnersFuel)--
        :Select(function(_, fuelTypeName) return fuelTypeName end)
end

function Class:GetBonusFromEffect(target)
    local type = target.type
    local prototype = Helper.CreatePrototypeProxy {
        type = "Bonus",
        name = (type .. "-modifier-icon"):gsub("-", "_"),
        localised_name = { "gui-bonus." .. type },
        localised_description = { "modifier-description." .. type },
        modifier = target.modifier,
    }

    local name = type .. "/" .. tostring(target.mining)
    return self:GetProxy("Bonus", name, prototype)
end

function Class:GetStackOfGoods(target)
    local amounts = {
        value = target.amount,
        probability = target.probability,
        min = target.amount_min,
        max = target.amount_max,
        temperature = target.temperature,
        catalyst_amount = target.catalyst_amount,
    }
    if not next(amounts) then amounts = nil end
    local goods--
    = target.type == "item" and self:GetItem(target.name) --
        or target.type == "fluid" and self:GetFluid(target.name) --
        or target.type == "entity" and self:GetEntity(target.name) --
    dassert(goods)
    if goods then return StackOfGoods:new(goods, amounts, self) end
end

function Class:CreateStackFromGoods(goods, amounts) return StackOfGoods:new(goods, amounts, self) end

function Class:GetFromBackLink(target)
    local className = self.ClassNameFromGameType[target.Type] or target.Type
    local prototype = target.Prototype
    dassert(type(className) == "string")
    dassert(not target.Name or type(target.Name) == "string")
    dassert(target.Name or prototype)
    return self:GetProxy(className, target.Name, prototype)
end

function Class:GetFromSelection(target)
    local className, prototype
    local name = target.name
    if target.base_type == "item" then
        className = "Item"
    elseif target.base_type == "entity" then
        className = "Entity"
    elseif target.base_type == "recipe" then
        className = "Recipe"
    elseif target.base_type == "technology" then
        className = "Technology"
    elseif target.base_type == "item-group" then
        return
    else
        dassert()
    end
    dassert(className)
    dassert(name or prototype)
    return self:GetProxy(className, name, prototype)
end

function Class:BeginMulipleQueueResearch(target, setting)
    Class.IsMulipleQueueResearch = true
    local result = target:BeginMulipleQueueResearch(setting)
    Class.IsMulipleQueueResearch = nil
    return result
end

function Class:RefreshTechnology(target)
    dassert(target.object_name == "LuaTechnology")
    self:GetTechnology(target.name):Refresh()
end

function Class:GetCountInInventory(goods)
    if goods.class == Proxy.Item then
        return self.Player.get_main_inventory().get_item_count(goods.Name)
    else
        return 0
    end
end

function Class:GetCountAvailable(goods)
    local inventory = self:GetCountInInventory(goods)
    local hand = self:GetCountInHand(goods)
    return inventory + hand
end

function Class:GetCountInHand(goods)
    if goods.class == Proxy.Item then
        local hand = self.Player.cursor_stack
        if hand.valid_for_read and hand.prototype.name == goods.Name then return hand.count end
    end
    return 0
end

--- Get craftable count and recipe for target (item or recipe)
---@param target table
function Class:GetCraftableCount(target)
    if target.class == Proxy.Item then
        local recipeCandidates = target.CreatedBy["Crafting.crafting"]
        local result = 0
        local recipe
        if recipeCandidates then
            recipeCandidates--
                :Select(
                    function(recipeCandidate)
                        local count = self:GetCraftableCount(recipeCandidate)
                        if result < count then
                            result = count
                            recipe = recipeCandidate
                        end
                    end
                ) --
        end
        return result, recipe
    elseif target.class == Proxy.Recipe then
        if self.Player.controller_type == defines.controllers.character then
            return self.Player.get_craftable_count(target.Name), target
        else
            return 0, target
        end
    end
end

function Class:GetRecipesGroupByCategory(prototype, direction)
    dassert(direction == "ingredients" or direction == "products")
    local backLink = self:GetBackLinkFromPrototype(prototype)
    local target = self:GetBackLinkFromPrototype(prototype)[direction]
    if not target then return Dictionary:new() end

    local result = Dictionary:new()
    Dictionary:new(Configurations.RecipeDomains)
        :Select(function(setup, key)
            local setup = setup.Recipe
            local backLinkRecipes = target[setup.GameType]
            if backLinkRecipes then
                local xreturn = Dictionary:new(backLinkRecipes)
                    :Select(function(recipeData, recipeName)
                        local prototype = recipeData.Proxy.Prototype
                        local proxy = self:GetProxy(setup.ClassName or setup.GameType, recipeName, prototype)
                        CoreHelper.EnsureKey(result, proxy.Category.Name, Array:new())
                            :Append(proxy)
                    end)
                return xreturn
            end
        end)
    return result
end

function Class:GetBackLinkFromPrototype(prototype)
    return self.Game[CoreHelper.GetObjectType(prototype)][prototype.name]
end

function Class:GetUsedByRecipes(prototype)
    local xreturn = self:GetRecipesGroupByCategory(prototype, "ingredients")
    return xreturn
end

function Class:GetCreatedByRecipes(prototype)
    local xreturn = self:GetRecipesGroupByCategory(prototype, "products")
    return xreturn
end

function Class:GetTranslation(type, name, tag)
    local dictionary = self.PlayerGlobal.Localisation[tag]
    if not dictionary then return end
    local result = dictionary[type .. "." .. name]
    return result
end

function Class:GetFilteredProxy(prototype) return MetaDataScan:GetFilteredProxy(prototype) end

function Class:Scan()
    MetaDataScan:Scan()
end

function Class:Print(text) self.Player.print { "", "[ingteb]", text } end

-- Event handler

function Class:OnInitialise()
    self:Scan()
end

function Class:OnConfigurationChanged(event)
    if migration.on_config_changed(event, {}) then
        self:Scan()
    end
end

function Class:OnMigration()
    self:Scan()
end

function Class:OnLoaded()
    if (__DebugAdapter and __DebugAdapter.instrument) then
        self:Scan()
    end
end

function Class:OnResearchChanged(event) self:RefreshTechnology(event.research) end

function Class:OnResearchQueueChanged(event)
    Dictionary:new(event.research)
        :Select(function(_, name)
            self:GetTechnology(name):Refresh()
        end)
end

return Class
