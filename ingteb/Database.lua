local translation = require("__flib__.translation")
local Number = require("core.Number")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local TimeSpan = require("core.TimeSpan")
local Proxy = {
    BoilingRecipe = require("ingteb.BoilingRecipe"),
    Bonus = require("ingteb.Bonus"),
    BurningRecipe = require("ingteb.BurningRecipe"),
    Category = require("ingteb.Category"),
    Entity = require("ingteb.Entity"),
    FuelCategory = require("ingteb.FuelCategory"),
    Fluid = require("ingteb.Fluid"),
    Item = require("ingteb.Item"),
    MiningRecipe = require("ingteb.MiningRecipe"),
    Recipe = require("ingteb.Recipe"),
    RocketLaunchRecipe = require("ingteb.RocketLaunchRecipe"),
    Technology = require("ingteb.Technology"),
    ModuleCategory = require("ingteb.ModuleCategory"),
    ModuleEffect = require("ingteb.ModuleEffect"),
}
---comment
---@param data table
---@param key string
---@param value any
---@return any
local function EnsureKey(data, key, value)
    local result = data[key]
    if not result then
        result = value or {}
        data[key] = result
    end
    return result
end

local StackOfGoods = require("ingteb.StackOfGoods")

local Class = class:new(
    "Database", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        ProductionTimeUnit = {
            cache = "player",
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
                result.Groups = Dictionary:new{}
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
                                and {goods.group.name, goods.subgroup.name} --
                            or {"other", type}

                            local group = EnsureKey(result.Groups, grouping[1], Dictionary:new{})
                            local subgroup = EnsureKey(group, grouping[2], Array:new{})
                            subgroup:Append(self:GetProxy(type, name, goods))
                            if maximumColumnCount < subgroup:Count() then
                                maximumColumnCount = subgroup:Count()
                            end
                        end
                    end
                end
                result.ColumnCount = maximumColumnCount < ColumnCount and maximumColumnCount
                                         or result.Groups:Count() * 2
                log("database initialize Selector complete.")
                return result
            end,
        },
    }
)

function Class:new(parent) return self:adopt{Parent = parent} end

function Class:OnSettingsChanged() self.cache.Database.ProductionTimeUnit.IsValid = false end

function Class:GetItemsPerTickText(amounts, timeInSeconds)
    if not timeInSeconds then return "" end
    local amount = amounts.value or (amounts.max + amounts.min) / 2
    return " ("
               .. Number:new(self.ProductionTimeUnit:getTicks() * amount / (timeInSeconds * 60)).Format3Digits
               .. "[img=items-per-timeunit]" .. ")"
end

function Class:Ensure()
    if self.IsInitialized then return self end
    local order = 1
    self.Order = {
        Recipe = 1,
        MiningRecipe = 2,
        BoilingRecipe = 3,
        BurningRecipe = 3.4,
        FuelRecipe = 3.5,
        RocketLaunchRecipe = 3.6,
        Technology = 4,
        Entity = 5,
        Bonus = 6,
        Item = 7,
        Fluid = 8,
        FuelCategory = 9,
        ModuleCategory = 10,
        ModuleEffect = 11,
        StackOfGoods = 12,
    }

    self.IsInitialized = "pending"

    log("database initialize start...")
    self:OnSettingsChanged()
    self.UsedByRecipesForItems = {}
    self.CreatedByRecipesForItems = {}
    self.CategoryNames = Dictionary:new{}
    self.RecipesForCategory = {}
    self.TechnologiesForRecipe = {}
    self.EnabledTechnologiesForTechnology = {}
    self.ResearchingTechnologyForItems = {}
    self.ItemsForFuelCategory = {}
    self.EntitiesForBurnersFuel = {}
    self.WorkersForCategory = Dictionary:new{}
    self.Resources = {}
    self.ItemsForModuleEffects = {}
    self.ItemsForModuleCategory = {}
    self.EntitiesForModuleEffects = {}
    self.Proxies = {}

    log("database scan recipes ...")
    for _, prototype in pairs(game.recipe_prototypes) do self:ScanRecipe(prototype) end
    log("database scan technologies ...")
    for _, prototype in pairs(game.technology_prototypes) do self:ScanTechnology(prototype) end
    log("database scan items ...")
    for _, prototype in pairs(game.item_prototypes) do self:ScanItem(prototype) end
    log("database scan fluids ...")
    for _, prototype in pairs(game.fluid_prototypes) do self:ScanFluid(prototype) end
    log("database scan entities ...")
    for _, prototype in pairs(game.entity_prototypes) do self:ScanEntity(prototype) end

    log("database special things...")
    self.CategoryNames:Select(
        function(value, categoryName)
            EnsureKey(self.RecipesForCategory, categoryName, Dictionary:new{})
            EnsureKey(self.WorkersForCategory, categoryName, Dictionary:new{})
            return self:GetCategory(categoryName)
        end
    )
    for name, prototype in pairs(game.fuel_category_prototypes) do
        EnsureKey(self.ItemsForFuelCategory, name, Array:new())
    end

    log("database initialize recipes...")
    self.Proxies.Category:Select(function(category) return category.RecipeList end)

    log("database initialize complete.")
    self.IsInitialized = true
    return self
end

function Class:GetProxyFromCommonKey(targetKey)
    self:Ensure()
    local _, _, className, prototypeName = targetKey:find("^(.-)%.(.*)$")
    local result = self:GetProxy(className, prototypeName)
    return result
end

function Class:GetProxyFromPrototype(prototype)
    self:Ensure()
    local objectType = prototype.object_name
    if objectType == "LuaFluidPrototype" then
        return self:GetFluid(nil, prototype)
    elseif objectType == "LuaItemPrototype" then
        return self:GetItem(nil, prototype)
    elseif objectType == "LuaEntityPrototype" then
        return self:GetEntity(nil, prototype)
    else
        dassert(false)
    end
end

function Class:GetProxy(className, name, prototype)
    local data = EnsureKey(self.Proxies, className, Dictionary:new())
    local key = name or prototype.name

    local result = data[key]
    dassert(result ~= "pending")

    if not result then
        data[key] = "pending"
        result = Proxy[className]:new(name, prototype, self)
        data[key] = result
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
    return self:GetProxy("MiningRecipe", name, prototype)
end

function Class:GetBoilingRecipe(name, prototype) --
    return self:GetProxy("BoilingRecipe", name, prototype)
end

function Class:GetBurningRecipe(name, prototype) --
    return self:GetProxy("BurningRecipe", name, prototype)
end

function Class:GetRocketLaunchRecipe(name, prototype) --
    return self:GetProxy("RocketLaunchRecipe", name, prototype)
end

function Class:GetFuelCategory(name, prototype) --
    return self:GetProxy("FuelCategory", name, prototype)
end

function Class:GetFuelCategories()
    return Dictionary:new(self.EntitiesForBurnersFuel) --
    :Select(function(_, fuelTypeName) return fuelTypeName end)
end

function Class:GetBonusFromEffect(target)
    local type = target.type
    local prototype = {
        name = (type .. "-modifier-icon"):gsub("-", "_"),
        localised_name = {"gui-bonus." .. type},
        localised_description = {"modifier-description." .. type},
        modifier = target.modifier,
    }

    local name = type .. "/" .. tostring(target.mining)
    return self:GetProxy("Bonus", name, prototype)
end

---@param categoryName string
---@param prototype table LuaEntityPrototype
function Class:AddWorkerForCategory(categoryName, prototype)
    local data = EnsureKey(self.WorkersForCategory, categoryName, Dictionary:new{})
    data[prototype.name] = prototype
    self.CategoryNames[categoryName] = true
end

---@param categoryName string
---@param prototype table LuaEntityPrototype
function Class:AddRecipesForCategory(categoryName, prototype)
    local data = EnsureKey(self.RecipesForCategory, categoryName, Dictionary:new{})
    data[prototype.name] = prototype
    self.CategoryNames[categoryName] = true
end

local function EnsureRecipeForItem(result, itemName, recipe)
    EnsureKey(result, itemName, Array:new{}):Append(recipe)
end

local function IsValidBoiler(prototype)
    local fluidBoxes = Array:new(prototype.fluidbox_prototypes)
    if not fluidBoxes then
        log {
            "mod-issue.boiler-without-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    end
    local inBoxes --
    = fluidBoxes --
    :Where(
        function(box)
            return box.production_type == "input" or box.production_type == "input-output"
        end
    ) --
    local outBoxes = fluidBoxes --
    :Where(function(box) return box.production_type == "output" end) --

    local result = true
    if not inBoxes or inBoxes:Count() ~= 1 then
        log {
            "mod-issue.boiler-no-unique-input-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    elseif not inBoxes[1].filter then
        log {
            "mod-issue.boiler-generic-input-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    end

    if not outBoxes or outBoxes:Count() ~= 1 then
        log {
            "mod-issue.boiler-no-unique-output-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    elseif not outBoxes[1].filter then
        log {
            "mod-issue.boiler-generic-output-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    end

    return result
end

function Class:ScanEntity(prototype)
    -- if prototype.type == "assembling-machine" or prototype.type == "furnace" then __DebugAdapter.breakpoint() end

    if prototype.fluid_energy_source_prototype then
        self:AddWorkerForCategory("fluid-burning.fluid", prototype)
    end

    for category, _ in pairs(prototype.crafting_categories or {}) do
        self:AddWorkerForCategory("crafting." .. category, prototype)
        if prototype.fixed_recipe then
            self:AddRecipesForCategory(
                "crafting." .. category, game.recipe_prototypes[prototype.fixed_recipe]
            )
        end
    end

    for category, _ in pairs(prototype.resource_categories or {}) do
        if #prototype.fluidbox_prototypes > 0 then
            self:AddWorkerForCategory("fluid-mining." .. category, prototype)
        end
        self:AddWorkerForCategory("mining." .. category, prototype)
    end

    if prototype.burner_prototype then
        if prototype.burner_prototype.fuel_inventory_size > 0 then
            for category, _ in pairs(prototype.burner_prototype.fuel_categories or {}) do
                EnsureKey(self.EntitiesForBurnersFuel, category, Array:new()):Append(prototype.name)
                self:AddWorkerForCategory("burning." .. category, prototype)
            end
        else
            log {
                "mod-issue.burner-without-fuel-inventory",
                prototype.localised_name,
                prototype.type .. "." .. prototype.name,
            }
        end
    end

    if prototype.type == "boiler" and IsValidBoiler(prototype) then
        self:AddWorkerForCategory("boiling." .. prototype.name, prototype)
        self:AddRecipesForCategory("boiling." .. prototype.name, prototype)
    end

    if prototype.type == "rocket-silo" then
        self:AddWorkerForCategory("rocket-launch.rocket-launch", prototype)
    end

    if prototype.type == "lab" then
        self:AddWorkerForCategory("researching." .. prototype.name, prototype)
    end

    if prototype.mineable_properties --
    and prototype.mineable_properties.minable --
    and prototype.mineable_properties.products --
    and not prototype.items_to_place_this --
    then
        local isFluidMining = prototype.mineable_properties.required_fluid --
                                  or Array:new(prototype.mineable_properties.products) --
            :Any(function(product) return product.type == "fluid" end) --

        local domain = not prototype.resource_category and "hand-mining" --
        or isFluidMining and "fluid-mining" --
        or "mining"

        local categoryName = not prototype.resource_category and "steel-axe" --
                                 or prototype.resource_category

        self:AddRecipesForCategory(domain .. "." .. categoryName, prototype)
    end

    if prototype.type == "character" and prototype.name == "character" then
        self:AddWorkerForCategory("hand-mining.steel-axe", prototype)
    end

    for name, value in pairs(prototype.allowed_effects or {}) do
        EnsureKey(self.EntitiesForModuleEffects, name, Array:new()):Append(prototype)
    end
end

function Class:CreateHandMiningCategory() self:GetCategory("hand-mining.steel-axe") end

function Class:ScanTechnology(prototype)
    for _, value in pairs(prototype.effects or {}) do
        if value.type == "unlock-recipe" then
            EnsureKey(self.TechnologiesForRecipe, value.recipe, Array:new()):Append(prototype)
        end
    end
    for key, _ in pairs(prototype.prerequisites or {}) do
        EnsureKey(self.EnabledTechnologiesForTechnology, key, Array:new()):Append(prototype)
    end

    for _, item in pairs(prototype.research_unit_ingredients or {}) do
        dassert(item.type == "item")
        EnsureKey(self.ResearchingTechnologyForItems, item.name, Array:new()):Append(prototype)
    end

end

function Class:ScanFuel(prototype, domainName, subName)
    if prototype.fuel_value and prototype.fuel_value > 0 then
        local subName = subName or "~"
        EnsureKey(self.ItemsForFuelCategory, subName, Array:new()):Append(prototype)
        local categoryName = domainName .. "." .. subName
        self:AddRecipesForCategory(categoryName, prototype)
    end
end

function Class:ScanFluid(prototype) self:ScanFuel(prototype, "fluid-burning", "fluid") end

function Class:ScanItem(prototype)
    self:ScanFuel(prototype, "burning", prototype.fuel_category)

    if prototype.burnt_result and not prototype.fuel_category then
        log {
            "mod-issue.burnt-result-without-fuel-category",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
            prototype.burnt_result.localised_name,
            prototype.burnt_result.type .. "." .. prototype.burnt_result.name,
        }
    end

    if #prototype.rocket_launch_products > 0 then
        self:AddRecipesForCategory("rocket-launch.rocket-launch", prototype)
    end

    for name in pairs(prototype.module_effects or {}) do
        EnsureKey(self.ItemsForModuleEffects, name, Array:new()):Append(prototype)
    end

    if prototype.category then
        EnsureKey(self.ItemsForModuleCategory, prototype.category, Array:new()):Append(prototype)
    end
end

function Class:ScanRecipe(prototype)
    self:AddRecipesForCategory("crafting." .. prototype.category, prototype)
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
    local goods --
    = target.type == "item" and self:GetItem(target.name) --
    or target.type == "fluid" and self:GetFluid(target.name) --
    if goods then return StackOfGoods:new(goods, amounts, self) end
end

function Class:CreateStackFromGoods(goods, amounts) return StackOfGoods:new(goods, amounts, self) end

function Class:Get(target)
    local className, name, prototype
    if not target or target == "" then
        return
    elseif type(target) == "string" then
        return self:GetProxyFromCommonKey(target)
    elseif target.object_name then
        return self:GetProxyFromPrototype(target)
    elseif target.type then
        if target.type == "item" then
            className = "Item"
        elseif target.type == "fluid" then
            className = "Fluid"
        else
            dassert()
        end
        name = target.name
    else
        className = target.class.name
        name = target.Name
        prototype = target.Prototype
    end
    self:Ensure()
    dassert(className)
    dassert(name or prototype)
    return self:GetProxy(className, name, prototype)
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
    self:Ensure()
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

function Class:OnResearchChanged(event) self:RefreshTechnology(event.research) end

function Class:RefreshTechnology(target)
    dassert(target.object_name == "LuaTechnology")
    self:GetTechnology(target.name):Refresh()
end
function Class:Print(text) self.Player.print {"", "[ingteb]", text} end

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
        local recipeCandidates = target.CreatedBy["crafting.crafting"]
        local result = 0
        local recipe
        if recipeCandidates then
            recipeCandidates --
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

function Class:OnStringTranslated(event)
    local names, finished = translation.process_result(event)
    if names then
        local result = event.translated and event.result or false
        for tag, keys in pairs(names) do
            for _, key in ipairs(keys) do
                local target = self:GetProxyFromCommonKey(key)
                target.Translation[tag] = result
            end
        end
    end
    if finished then
        -- dassert() 
    end
end

function Class:GetRecipesGroupByCategory(recipes)
    if recipes then
        local xreturn = recipes:ToGroup(
            function(recipe) return {Key = recipe.Category.Name, Value = recipe} end
        )
        return xreturn
    end
    return Dictionary:new{}
end

function Class:GetUsedByRecipes(itemName)
    local xreturn = self:GetRecipesGroupByCategory(self.UsedByRecipesForItems[itemName])
    return xreturn
end

function Class:GetCreatedByRecipes(itemName)
    local xreturn = self:GetRecipesGroupByCategory(self.CreatedByRecipesForItems[itemName])
    return xreturn
end

function Class:EnsureUsage(recipe, input, output)
    if input then
        for _, value in ipairs(input) do
            if value.type ~= "resource" then
                EnsureRecipeForItem(self.UsedByRecipesForItems, value.name, recipe)
            end
        end
    end
    if output then
        for _, value in ipairs(output) do
            EnsureRecipeForItem(self.CreatedByRecipesForItems, value.name, recipe)
        end
    end
end

return Class

