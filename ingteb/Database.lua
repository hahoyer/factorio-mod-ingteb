local translation = require("__flib__.translation")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local Proxy = {
    BoilingRecipe = require("ingteb.BoilingRecipe"),
    Bonus = require("ingteb.Bonus"),
    Category = require("ingteb.Category"),
    Entity = require("ingteb.Entity"),
    FuelCategory = require("ingteb.FuelCategory"),
    Fluid = require("ingteb.Fluid"),
    Item = require("ingteb.Item"),
    MiningRecipe = require("ingteb.MiningRecipe"),
    Recipe = require("ingteb.Recipe"),
    Technology = require("ingteb.Technology"),
}

local StackOfGoods = require("ingteb.StackOfGoods")

local Class = class:new(
    "Database", nil, {Player = {get = function(self) return self.Parent.Player end}}
)

function Class:new(parent) return self:adopt{Parent = parent} end

local function EnsureKey(data, key, value)
    local result = data[key]
    if not result then
        result = value or {}
        data[key] = result
    end
    return result
end

function Class:Ensure()
    if self.IsInitialized then return self end
    self.Order = {
        Recipe = 1,
        MiningRecipe = 2,
        BoilingRecipe = 3,
        Technology = 4,
        Entity = 5,
        Bonus = 6,
        Item = 7,
        Fluid = 8,
        FuelCategory = 9,
        StackOfGoods = 10,
    }

    self.IsInitialized = "pending"

    log("database initialize start...")
    self.RecipesForItems = {}
    self.RecipesForCategory = {}
    for _, prototype in pairs(game.recipe_prototypes) do self:ScanRecipe(prototype) end

    self.TechnologiesForRecipe = {}
    self.EnabledTechnologiesForTechnology = {}
    self.ResearchingTechnologyForItems = {}
    for _, prototype in pairs(game.technology_prototypes) do self:ScanTechnology(prototype) end

    self.ItemsForFuelCategory = {}
    for _, prototype in pairs(game.item_prototypes) do self:ScanItem(prototype) end

    self.EntitiesForBurnersFuel = {}
    self.WorkersForCategory = {}
    self.Resources = {}
    for _, prototype in pairs(game.entity_prototypes) do self:ScanEntity(prototype) end

    log("database initialize proxies...")
    self.Proxies = {
        MiningRecipe = Dictionary:new{},
        BoilingRecipe = Dictionary:new{},
        Category = Dictionary:new{},
        Fluid = Dictionary:new{},
        Recipe = Dictionary:new{},
        Technology = Dictionary:new{},
        Entity = Dictionary:new{},
    }

    for categoryName in pairs(self.RecipesForCategory) do
        EnsureKey(self.WorkersForCategory, categoryName, Array:new())
    end

    log("database initialize categories...")
    self:CreateBoilerRecipe()
    self:CreateHandMiningCategory()
    self.Proxies.Item = Dictionary:new{}
    self.Proxies.FuelCategory = Dictionary:new{}
    for categoryName in pairs(self.WorkersForCategory) do self:GetCategory(categoryName) end

    log("database initialize recipes...")
    self.Proxies.Category:Select(function(category) return category.RecipeList end)

    self.Proxies.Bonus = Dictionary:new{}

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

function Class:GetProxy(className, name, prototype)
    local data = self.Proxies[className]
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
function Class:GetMiningRecipe(name, prototype) return
    self:GetProxy("MiningRecipe", name, prototype) end
function Class:GetBoilingRecipe(name, prototype)
    return self:GetProxy("BoilingRecipe", name, prototype)
end
function Class:GetTechnology(name, prototype) return self:GetProxy("Technology", name, prototype) end
function Class:GetFuelCategory(name, prototype) return
    self:GetProxy("FuelCategory", name, prototype) end

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

---@param domain string
---@param category string
---@param prototype table LuaEntityPrototype
function Class:AddWorkerForCategory(domain, category, prototype)
    EnsureKey(self.WorkersForCategory, domain .. "." .. category, Array:new{}):Append(prototype)
end

local function EnsureRecipeCategory(result, side, name, category)
    local itemData = EnsureKey(result, name)
    local sideData = EnsureKey(itemData, side, Dictionary:new())
    local categoryData = EnsureKey(sideData, "crafting." .. category, Array:new())
    return categoryData
end

function Class:ScanEntity(prototype)
    for category, _ in pairs(prototype.crafting_categories or {}) do
        self:AddWorkerForCategory("crafting", category, prototype)
    end

    for category, _ in pairs(prototype.resource_categories or {}) do
        if #prototype.fluidbox_prototypes > 0 then
            self:AddWorkerForCategory("fluid-mining", category, prototype)
        end
        self:AddWorkerForCategory("mining", category, prototype)
    end

    if prototype.burner_prototype then
        for category, _ in pairs(prototype.burner_prototype.fuel_categories or {}) do
            EnsureKey(self.EntitiesForBurnersFuel, category, Array:new()):Append(prototype.name)
        end
    end

    if prototype.mineable_properties --
    and prototype.mineable_properties.minable --
    and prototype.mineable_properties.products --
    and not prototype.items_to_place_this --
    then
        local isFluidMining = prototype.mineable_properties.required_fluid --
                                  or Array:new(prototype.mineable_properties.products) --
            :Any(function(product) return product.type == "fluid" end) --

        local category = not prototype.resource_category and "hand-mining.steel-axe" --
                             or (isFluidMining and "fluid-mining." or "mining.")
                             .. prototype.resource_category

        EnsureKey(self.RecipesForCategory, category, Array:new()):Append(prototype.name)
    end

    if prototype.type == "character" and prototype.name == "character" then
        self:AddWorkerForCategory("hand-mining", "steel-axe", prototype)
    end
end

function Class:CreateHandMiningCategory() self:GetCategory("hand-mining.steel-axe") end

function Class:CreateBoilerRecipe()
    local prototype = game.entity_prototypes.boiler
    self:AddWorkerForCategory("boiling", "steam", prototype)
    self:GetBoilingRecipe("steam", prototype)
end

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

function Class:ScanItem(prototype)
    if prototype.fuel_category then
        EnsureKey(self.ItemsForFuelCategory, prototype.fuel_category, Array:new()):Append(prototype)
    end
end

function Class:ScanRecipe(prototype)

    if prototype.hidden then return end
    -- if prototype.hidden_from_player_crafting then return end

    for _, itemSet in pairs(prototype.ingredients) do
        EnsureRecipeCategory(self.RecipesForItems, "UsedBy", itemSet.name, prototype.category) --
        :Append(prototype.name)
    end

    for _, itemSet in pairs(prototype.products) do
        EnsureRecipeCategory(self.RecipesForItems, "CreatedBy", itemSet.name, prototype.category) --
        :Append(prototype.name)
    end

    EnsureKey(self.RecipesForCategory, "crafting." .. prototype.category, Array:new()) --
    :Append(prototype.name)

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
    local className, Name
    if not target or target == "" then
        return
    elseif type(target) == "string" then
        return self:GetProxyFromCommonKey(target)
    elseif target.type then
        if target.type == "item" then
            className = "Item"
        elseif target.type == "fluid" then
            className = "Fluid"
        else
            dassert()
        end
        Name = target.name
    else
        className = target.class.name
        Name = target.Name
        Prototype = target.Prototype
    end
    self:Ensure()
    dassert(className)
    dassert(Name or Prototype)
    return self:GetProxy(className, Name, Prototype)
end

function Class:GetFromSelection(target)
    local className
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
    dassert(name or Prototype)
    return self:GetProxy(className, name, Prototype)
end

function Class:BeginMulipleQueueResearch(target, setting)
    Class.IsMulipleQueueResearch = true
    local result = target:BeginMulipleQueueResearch(setting)
    Class.IsMulipleQueueResearch = nil
    if class.IsRefreshResearchChangedRequired then
        class.IsRefreshResearchChangedRequired = nil
        local current = self.Parent.Current
        if current then current:RefreshResearchChanged() end
    end

    return result
end

function Class:OnResearchChanged(event) self:RefreshTechnology(event.research) end

function Class:RefreshTechnology(target)
    dassert(target.object_name == "LuaTechnology")
    self:GetTechnology(target.name):Refresh()
end
function Class:Print(player, text) player.print {"", "[ingteb]", text} end

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

function Class:GetCraftableCount(target)
    if target.class == Proxy.Item then
        local recipes = target.CreatedBy["crafting.crafting"]
        local result = 0
        local recipe
        if recipes then
            recipes --
            :Select(
                function(recipe)
                    local count = self:GetCraftableCount(recipe)
                    if result < count then
                        result = count
                        recipe = recipe
                    end
                end
            ) --
        end
        return result, recipe
    elseif target.class == Proxy.Recipe then
        return self.Player.get_craftable_count(target.Name)
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

return Class

