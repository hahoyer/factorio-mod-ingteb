local localisation = require "__flib__.dictionary"
local Number = require("core.Number")
local Constants = require("Constants")
local Helper = require "ingteb.Helper"
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local TimeSpan = require("core.TimeSpan")
local Proxy = {
    Bonus = require("ingteb.Bonus"),
    BurningRecipe = require("ingteb.BurningRecipe"),
    Category = require("ingteb.Category"),
    Entity = require("ingteb.Entity"),
    FuelCategory = require("ingteb.FuelCategory"),
    Fluid = require("ingteb.Fluid"),
    Item = require("ingteb.Item"),
    Recipe = require("ingteb.Recipe"),
    RecipeCommon = require "ingteb.RecipeCommon",
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
    Player = { get = function(self) return self.Parent.Player end },
    Global = { get = function(self) return self.Parent.Global end },
    BackLinks = {
        get = function(self)
            if not global.Database then global.Database = {} end
            if not global.Database.BackLinks then global.Database.BackLinks = {} end
            return global.Database.BackLinks
        end,
    },
    Proxies = {
        get = function(self)
            if not global.Database then global.Database = {} end
            if not global.Database.Proxies then global.Database.Proxies = {} end
            return global.Database.Proxies
        end,
    },
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

                        local group = EnsureKey(result.Groups, grouping[1], Dictionary:new {})
                        local subgroup = EnsureKey(group, grouping[2], Array:new {})
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

function Class:new(parent) return self:adopt { Parent = parent } end

function Class:GetItemsPerTickText(amounts, ticks)
    if not ticks then return "" end
    local amount = amounts.value or (amounts.max + amounts.min) / 2
    return " ("
        .. Number:new(self.ProductionTimeUnit:getTicks() * amount / ticks).Format3Digits
        .. "[img=items-per-timeunit]" .. ")"
end

function Class:ScanBackLinks()
    log("database scan backLinks ...")
    local backLinks = self.BackLinks
    backLinks.CategoryNames = Dictionary:new {}
    backLinks.RecipesForCategory = {}
    backLinks.TechnologiesForRecipe = {}
    backLinks.EnabledTechnologiesForTechnology = {}
    backLinks.ResearchingTechnologyForItems = {}
    backLinks.ItemsForFuelCategory = {}
    backLinks.EntitiesForBurnersFuel = {}
    backLinks.WorkersForCategory = {}
    backLinks.Resources = {}
    backLinks.ItemsForModuleEffects = {}
    backLinks.ItemsForModuleCategory = {}
    backLinks.EntitiesForModuleEffects = {}
    backLinks.Recipe = {
        Input = { item = {}, fluid = {}, entity = {} },
        Output = { item = {}, fluid = {} }
    }

    log("database backLinks : scan recipes ...")
    for _, prototype in pairs(game.recipe_prototypes) do self:ScanRecipe(prototype) end
    log("database scan technologies ...")
    for _, prototype in pairs(game.technology_prototypes) do self:ScanTechnology(prototype) end
    log("database backLinks : scan items ...")
    for _, prototype in pairs(game.item_prototypes) do self:ScanItem(prototype) end
    log("database backLinks : scan fluids ...")
    for _, prototype in pairs(game.fluid_prototypes) do self:ScanFluid(prototype) end
    log("database backLinks : scan entities ...")
    for _, prototype in pairs(game.entity_prototypes) do self:ScanEntity(prototype) end
    log("database backLinks : scan fuel_category_prototypes ...")
    for name in pairs(game.fuel_category_prototypes) do
        EnsureKey(backLinks.ItemsForFuelCategory, name, Array:new())
    end

    log("database backLinks : scan player ...")
    self:AddWorkerForCategory("hand-mining.steel-axe", self.Player.character.prototype)

    log("database backLinks : ensure category-entries ...")
    backLinks.CategoryNames:Select(
        function(value, categoryName)
        EnsureKey(backLinks.RecipesForCategory, categoryName, Dictionary:new {})
        EnsureKey(backLinks.WorkersForCategory, categoryName, Dictionary:new {})
    end
    )

    log("database scan backLinks complete.")
end

function Class:Ensure()
    if self.IsInitialized then return self end
    self.Global.Translation = nil
    local order = 1
    self.Order = {
        Recipe = 1,
        RecipeCommon = 2,
        BurningRecipe = 3,
        FuelRecipe = 3.5,
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
    self:ScanBackLinks()

    local proxies = self.Proxies
    while next(proxies) do proxies[next(proxies)] = nil end

    log("database initialize categories and recipes ...")
    self.BackLinks.CategoryNames:Select(
        function(_, categoryName)
        local recipes = self:GetCategory(categoryName).AllRecipes
    end
    )

    log("database initialize cleanup ...")
    self.CategoryNames = nil
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
    local objectType = prototype.object_name or prototype.type
    if objectType == "LuaFluidPrototype" then
        return self:GetFluid(nil, prototype)
    elseif objectType == "LuaItemPrototype" then
        return self:GetItem(nil, prototype)
    elseif objectType == "LuaEntityPrototype" then
        return self:GetEntity(nil, prototype)
    elseif objectType == "LuaRecipePrototype" then
        return self:GetRecipe(nil, prototype)
    elseif objectType == "burning" then
        return self:GetBurningRecipe(nil, prototype)
    elseif objectType == "boiling" then
        return self:GetBoilingRecipe(nil, prototype)
    elseif objectType == "mining" or objectType == "hand-mining" or objectType == "fluid-mining" then
        return self:GetMiningRecipe(nil, prototype)
    elseif objectType == "rocket-launch" then
        return self:GetRocketLaunchRecipe(nil, prototype)
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
    dassert(not name)
    return self:GetProxy("RecipeCommon", name, prototype)
end

function Class:GetBoilingRecipe(name, prototype) --
    dassert(not name)
    return self:GetProxy("RecipeCommon", name, prototype)
end

function Class:GetBurningRecipe(name, prototype) --
    dassert(not name)
    return self:GetProxy("BurningRecipe", name, prototype)
end

function Class:GetRocketLaunchRecipe(name, prototype) --
    dassert(not name)
    return self:GetProxy("RecipeCommon", name, prototype)
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

---@param categoryName string
---@param prototype table LuaEntityPrototype
function Class:AddWorkerForCategory(categoryName, prototype)
    local data = EnsureKey(self.BackLinks.WorkersForCategory, categoryName, Dictionary:new {})
    data[prototype.name] = prototype
    self.BackLinks.CategoryNames[categoryName] = true
end

---@param prototype table LuaEntityPrototype
function Class:AddRecipe(prototype)
    local type = prototype.object_name == "LuaRecipePrototype" and "crafting" or prototype.type

    dassert(type)
    dassert(prototype.name)
    dassert(prototype.ingredients)
    dassert(prototype.products)
    dassert(prototype.category)
    dassert(prototype.object_name == "LuaRecipePrototype" or prototype.hidden)

    local categoryName = type .. "." .. prototype.category

    self.BackLinks.CategoryNames[categoryName] = true

    local data = EnsureKey(self.BackLinks.RecipesForCategory, categoryName, Dictionary:new {})
    data[prototype.name] = prototype
    for _, value in ipairs(prototype.ingredients) do
        EnsureKey(self.BackLinks.Recipe.Input[value.type], value.name, Array:new()):Append(prototype)
    end
    for _, value in ipairs(prototype.products) do
        EnsureKey(self.BackLinks.Recipe.Output[value.type], value.name, Array:new()):Append(prototype)
    end
end

function Class:ScanEntity(prototype)
    -- if prototype.type == "assembling-machine" or prototype.type == "furnace" then __DebugAdapter.breakpoint() end

    if prototype.fluid_energy_source_prototype then
        self:AddWorkerForCategory("fluid-burning.fluid", prototype)
    end

    for category, _ in pairs(prototype.crafting_categories or {}) do
        self:AddWorkerForCategory("crafting." .. category, prototype)
        if prototype.fixed_recipe then
            dassert(category == game.recipe_prototypes[prototype.fixed_recipe].category)
            self:AddRecipe(game.recipe_prototypes[prototype.fixed_recipe])
        end
    end

    for categoryName, _ in pairs(prototype.resource_categories or {}) do
        if categoryName == "basic-solid" then
            self:AddWorkerForCategory("mining" .. "." .. categoryName, prototype)
        end
        if #prototype.fluidbox_prototypes > 0 then
            self:AddWorkerForCategory("fluid-mining" .. "." .. categoryName, prototype)
        end
    end

    if prototype.burner_prototype then
        if prototype.burner_prototype.fuel_inventory_size > 0 then
            for category, _ in pairs(prototype.burner_prototype.fuel_categories or {}) do
                EnsureKey(self.BackLinks.EntitiesForBurnersFuel, category, Array:new()):Append(
                    prototype.name
                )
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

    if prototype.type == "boiler" and Helper.IsValidBoiler(prototype) then
        self:AddWorkerForCategory("boiling." .. prototype.name, prototype)
        self:AddRecipe(Helper.CalculateHeaterRecipe(prototype))
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
            or Array:new(prototype.mineable_properties.products)--
            :Any(function(product) return product.type == "fluid" end) --

        local domain = not prototype.resource_category and "hand-mining" --
            or isFluidMining and "fluid-mining" --
            or "mining"

        local categoryName = not prototype.resource_category and "steel-axe" --
            or prototype.resource_category

        local ingredients = { { type = "entity", name = prototype.name } }
        local configuration = prototype.mineable_properties
        if configuration.required_fluid then
            table.insert(
                ingredients, {
                type = "fluid",
                name = configuration.required_fluid,
                amount = configuration.fluid_amount,
            }
            )
        end

        self:AddRecipe(Helper.CreatePrototypeProxy
            {
                type = domain,
                Prototype = prototype,
                sprite_type = "entity",
                hidden = true,
                products = configuration.products,
                ingredients = ingredients,
                energy = configuration.mining_time,
                category = categoryName,
            }
        )
    end

    for name, value in pairs(prototype.allowed_effects or {}) do
        EnsureKey(self.BackLinks.EntitiesForModuleEffects, name, Array:new()):Append(prototype)
    end
end

function Class:CreateHandMiningCategory() self:GetCategory("hand-mining.steel-axe") end

function Class:ScanTechnology(prototype)
    for _, value in pairs(prototype.effects or {}) do
        if value.type == "unlock-recipe" then
            EnsureKey(self.BackLinks.TechnologiesForRecipe, value.recipe, Array:new()):Append(
                prototype
            )
        end
    end
    for key, _ in pairs(prototype.prerequisites or {}) do
        EnsureKey(self.BackLinks.EnabledTechnologiesForTechnology, key, Array:new()):Append(prototype)
    end

    for _, item in pairs(prototype.research_unit_ingredients or {}) do
        dassert(item.type == "item")
        EnsureKey(self.BackLinks.ResearchingTechnologyForItems, item.name, Array:new()):Append(
            prototype
        )
    end

end

function Class:ScanFuel(prototype, domain, category, isFluid)
    if prototype.fuel_value and prototype.fuel_value > 0 then
        local category = category or "~"
        EnsureKey(self.BackLinks.ItemsForFuelCategory, category, Array:new()):Append(prototype)
        local output = not isFluid and prototype.burnt_result
        local also = { "fuel_value" }
        if not isFluid then table.insert(also, "fuel_category") end
        self:AddRecipe(
            Helper.CreatePrototypeProxy { --
                type = domain,
                Prototype = prototype,
                hidden = true,
                category = category,
                sprite_type = isFluid and "fluid" or "item",
                Also = also,
                ingredients = { { type = self.IsFluid and "fluid" or "item", amount = 1, name = prototype.name } },
                products = output and { { type = output.type, amount = 1, name = output.name } } or {},

            })
    end
end

function Class:ScanFluid(prototype)
    self:ScanFuel(prototype, "fluid-burning", "fluid", true)
end

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
        self:AddRecipe(
            Helper.CreatePrototypeProxy {
                type = "rocket-launch",
                Prototype = prototype,
                category = "rocket-launch",
                sprite_type = "item",
                hidden = true,
                ingredients = { { type = "item", amount = prototype.default_request_amount, name = prototype.name } },
                products = prototype.rocket_launch_products

            }
        )
    end

    for name in pairs(prototype.module_effects or {}) do
        EnsureKey(self.BackLinks.ItemsForModuleEffects, name, Array:new()):Append(prototype)
    end

    if prototype.category then
        EnsureKey(self.BackLinks.ItemsForModuleCategory, prototype.category, Array:new()):Append(
            prototype
        )
    end
end

function Class:ScanRecipe(prototype)
    self:AddRecipe(prototype)
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
    local goods--
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

function Class:Print(text) self.Player.print { "", "[ingteb]", text } end

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

function Class:GetTranslation(commonKey)
    local dictionary = EnsureKey(self.Global, "Localisation")
    return EnsureKey(dictionary, commonKey)
end

function Class:OnStringTranslated(event)
    local language_data = localisation.process_translation(event)
    if not language_data then return end
    self.Global.Localisation = language_data.dictionaries
end

function Class:OnInitialiseLocalisation()
    localisation.init()
    self.Localisation = {
        Names = localisation.new("Names", true),
        Descriptions = localisation.new("Descriptions", true),
    }
end

function Class:AddTranslationRequest(commonKey, prototype)
    if not self.Localisation then self:OnInitialiseLocalisation() end
    self.Localisation.Names:add(commonKey, prototype.localised_name)
    self.Localisation.Descriptions:add(commonKey, prototype.localised_description)
end

function Class:OnInitialise() self:OnInitialiseLocalisation() end

function Class:OnConfigurationChanged() self:OnInitialiseLocalisation() end

function Class:GetRecipesGroupByCategory(target, prototype)
    local type = prototype.object_name == "LuaFluidPrototype" and "fluid"
        or prototype.object_name == "LuaItemPrototype" and "item"
        or prototype.object_name == "LuaEntityPrototype" and "entity"
        or prototype.type
    local recipes
    if target[type] then recipes = target[type][prototype.name] end
    if recipes then
        local xreturn = recipes:ToGroup(
            function(recipe)
            local proxy = self:GetProxyFromPrototype(recipe)
            return { Key = proxy.Category.Name, Value = proxy }
        end
        )

        return xreturn
    end
    return Dictionary:new {}
end

function Class:GetUsedByRecipes(prototype)
    local xreturn = self:GetRecipesGroupByCategory(self.BackLinks.Recipe.Input, prototype)
    return xreturn
end

function Class:GetCreatedByRecipes(prototype)
    local xreturn = self:GetRecipesGroupByCategory(self.BackLinks.Recipe.Output, prototype)
    return xreturn
end

return Class
