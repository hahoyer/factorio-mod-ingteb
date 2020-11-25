local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local ValueCacheContainer = require("core.ValueCacheContainer")
local Proxy = {
    Item = require("ingteb.Item"),
    Entity = require("ingteb.Entity"),
    Recipe = require("ingteb.Recipe"),
    Technology = require("ingteb.Technology"),
    ItemSet = require("ingteb.ItemSet"),
    Category = require("ingteb.Category"),
}
local ItemSet = require("ingteb.ItemSet")

function EnsureKey(data, key, value)
    local result = data[key]
    if not result then
        result = value or {}
        data[key] = result
    end
    return result
end

function EnsureRecipeCategory(result, side, name, category)
    local itemData = EnsureKey(result, name)
    local sideData = EnsureKey(itemData, side, Dictionary:new())
    local categoryData = EnsureKey(sideData, "crafting." ..category, Array:new())
    return categoryData
end

local Database = ValueCacheContainer:new{}
Database.object_name = "Database"

function Database:new()
    if self.Proxies then return self end
    self.Proxies = {}
    self.RecipesForItems = {}
    self.RecipesForCategory = {}

    for _, recipe in pairs(game.recipe_prototypes) do self:ScanRecipe(recipe) end

    for _, prototype in pairs(game.entity_prototypes) do
        for category, _ in pairs(prototype.crafting_categories or {}) do
            self:AddWorkerForCategory("crafting." .. category, prototype)
        end
        for category, _ in pairs(prototype.resource_categories or {}) do
            self:AddWorkerForCategory("mining." .. category, prototype)
        end
    end

    for _, prototype in pairs(game.technology_prototypes) do

        for key, value in pairs(prototype.effects or {}) do
            if value.type == "unlock-recipe" then
                self:GetRecipe(value.recipe).TechnologyPrototypes:Append(prototype)
            end
        end
    end

    return self
end

function Database:GetProxy(className, name, prototype)
    self = self:new()

    local data = self.Proxies[className]
    if not data then
        data = {}
        self.Proxies[className] = data
    end

    local key = name or prototype.name

    local result = data[key]
    if not result then
        result = Proxy[className]:new(name, prototype, self)
        data[key] = result
    end

    return result
end

function Database:GetItem(name, prototype) return self:GetProxy("Item", name, prototype) end
function Database:GetEntity(name, prototype) return self:GetProxy("Entity", name, prototype) end
function Database:GetCategory(name, prototype) return self:GetProxy("Category", name, prototype) end
function Database:GetRecipe(name, prototype) return self:GetProxy("Recipe", name, prototype) end
function Database:GetTechnology(name, prototype) return self:GetProxy("Technology", name, prototype) end

function Database:AddWorkerForCategory(category, prototype)
    self:GetCategory(category).Workers:Append(self:GetEntity(nil, prototype))
end

function Database:ScanRecipe(prototype)

    if prototype.hidden then return end

    for _, itemSet in pairs(prototype.ingredients) do
        EnsureRecipeCategory(self.RecipesForItems, "UsedBy", itemSet.name, prototype.category) --
        :Append(prototype.name)
    end

    for _, itemSet in pairs(prototype.products) do
        EnsureRecipeCategory(self.RecipesForItems, "CreatedBy", itemSet.name, prototype.category) --
        :Append(prototype.name)
    end

    EnsureKey(self.RecipesForCategory, prototype.category, Array:new()):Append(prototype.name)

end

function Database:GetHelperTextForPrototype(entity)
    local name = entity.localised_name
    local description = entity.localised_description
    local help = nil

    local result = name
    if self.HasLocalisedDescription then result = {"ingteb_utility.Lines2", result, description} end
    if help then result = {"ingteb_utility.Lines2", result, help} end
    return result
end

function Database:GetTechnologySpriteStyle(target)
    local dynamicTarget = global.Current.Player.force.technologies[target.name]
    if dynamicTarget.researched then return end
    return not Dictionary:new(dynamicTarget.prerequisites) --
    :Where(
        function(_, technology)
            return not global.Current.Player.force.technologies[technology].researched
        end
    ) --
    :Any()
end

function Database:GetTechnologySprite(recipe) return self.GetRecipe(nil, recipe).Technology end

function Database:GetWorkerSpritesForCategory(name)
    return self.Categories[name].Workers --
    :Select(
        function(target)
            return {
                MainObject = game.item_prototypes[target.name],
                HelperText = self:GetHelperTextForPrototype(target),
                SpriteName = "entity/" .. target.name,
                NumberOnSprite = nil,
                UsePercentage = nil,
                IsDynamic = nil,
                HasLocalisedDescriptionPending = nil,
                SpriteStyle = nil,
            }
        end
    )
end

function Database:GetRecipeSprite(target) return self:GetRecipe(nil, target) end

function Database:GetItemSetNumberOnSprite(target)
    local probability = (target.probability or 1)
    local value = target.amount

    if not value then
        if not target.amount_min then
            value = target.amount_max
        elseif not target.amount_max then
            value = target.amount_min
        else
            value = (target.amount_max + target.amount_min) / 2
        end
    elseif type(value) ~= "number" then
        return
    end

    return value * probability
end

function Database:GetItemSetSprite(target)
    local prototype
    if target.type == "item" then
        prototype = game.item_prototypes[target.name]
    elseif target.type == "fluid" then
        prototype = game.fluid_prototypes[target.name]
    else
        assert()
    end

    return {
        MainObject = prototype,
        HelperText = self:GetHelperTextForPrototype(prototype),
        SpriteName = target.type .. "/" .. target.name,
        NumberOnSprite = self:GetItemSetNumberOnSprite(target),
        UsePercentage = target.percentage ~= nil,
        IsDynamic = nil,
        HasLocalisedDescriptionPending = nil,
        SpriteStyle = nil,
    }

end

function Database:GetItemRecipeList(name)
    local entity = game.entity_prototypes[name]

    return Dictionary:new(entity and entity.crafting_categories or {}) --
    :Concat(Dictionary:new(entity and entity.resource_categories or {})) --
    :Select(function(_, category) return self.RecipesForCategory[category] end)
end

function Database:TypeOrder(type)
    return type == "LuaRecipePrototype" and 1 --
    or 1000
end

function Database:OrderValue(target)
    target = self.Recipes[target.name]
    return self:TypeOrder(target.Prototype.object_name) .. " " --
               .. (target.IsResearched and "R" or "r") .. " " --
               .. (not target.IsResearched and target.Technology.IsReady and "R" or "r") .. " " --
               .. target.Prototype.group.order .. " " --
    .. target.Prototype.subgroup.order .. " " --
    .. target.Prototype.order
end

function Database:GroupOrder(target) return self.Recipes[target.name].IsResearched and 1 or 0 end
function Database:GroupSubOrder(target)
    target = self.Recipes[target.name]
    return (not target.Technology or target.Technology.IsReady) and 1 or 0
end

function Database:Sort(target)
    if not target then return end
    local targetArray = target:ToArray(function(value, key) return {Value = value, Key = key} end)
    targetArray:Sort(
        function(a, b)
            if a == b then return false end
            local aOrder = a.Value:Select(
                function(recipe) return self:GetRecipe(nil, recipe).GroupOrder end
            ):Sum()
            local bOrder = b.Value:Select(
                function(recipe) return self:GetRecipe(nil, recipe).GroupOrder end
            ):Sum()
            if aOrder ~= bOrder then return aOrder > bOrder end

            local aSubOrder = a.Value:Select(
                function(recipe) return self:GetRecipe(nil, recipe).GroupSubOrder end
            ):Sum()
            local bSubOrder = b.Value:Select(
                function(recipe) return self:GetRecipe(nil, recipe).GroupSubOrder end
            ):Sum()
            return aSubOrder > bSubOrder

        end
    )

    -- assert()

    return targetArray:ToDictionary(
        function(value)
            value.Value:Sort(
                function(a, b) return self:GetRecipe(a):IsBefore(self:GetRecipe(b)) end
            )
            return value
        end
    )

end

function Database:GetItemUsedBy(name)
    local result = self.RecipesForItems[name].UsedBy
    self:Sort(result)
    return result
end

function Database:GetItemCreatedBy(name)
    local result = self.RecipesForItems[name].CreatedBy
    self:Sort(result)
    return result
end

function Database:GetDataForItemOld(prototype)
    self = self:new()
    return {
        LocalisedName = prototype.localised_name,
        SpriteName = "item/" .. prototype.name,
        RecipeList = self:GetItemRecipeList(prototype.name),
        UsedBy = self:GetItemUsedBy(prototype.name) or Dictionary:new(),
        CreatedBy = self:GetItemCreatedBy(prototype.name) or Dictionary:new(),
        SortAll = function() end,
    }
end

function Database:GetItemSet(target)
    local amounts = {
        value = target.amount,
        probability = target.probability,
        min = target.amount_min,
        max = target.amount_max,
    }
    local item --
    = target.type == "item" and self:GetItem(target.name) --
    or target.type == "fluid" and self:GetFluid(target.name) --
    if item then return ItemSet:new(item, amounts, self) end
end

function Database:EnsureCategory(domain, prototype)
    local categoryName = prototype.name .. " " .. domain
    if not self.Categories[categoryName] then
        self.Categories[categoryName] = Category(domain, prototype, self)
    end
end

function Database:AddBonus(target, technology)
    local result = self.Bonusses[target.type]
    if not result then
        result = Bonus(target.type, self)
        self.Bonusses[target.type] = result
    end
    result.CreatedBy:Append{Technology = technology, Modifier = target.modifier}

    return BonusSet(result, target.modifier, self)
end

function Database:OnLoad() self = self:new() end

function Database:FindTarget()
    local function get()
        local cursor = global.Current.Player.cursor_stack
        if cursor and cursor.valid and cursor.valid_for_read then
            return self.Items[cursor.name]
        end
        local cursor = global.Current.Player.cursor_ghost
        if cursor then return self.Items[cursor.name] end

        local cursor = global.Current.Player.selected
        if cursor then
            local result = self.Entities[cursor.name]
            if result.IsResource then
                return result
            else
                return result.Item
            end
        end

        local cursor = global.Current.Player.opened
        if cursor then

            local t = global.Current.Player.opened_gui_type
            if t == defines.gui_type.custom then return end
            if t == defines.gui_type.entity then return self.Entities[cursor.name] end

            assert()
        end
        -- local cursor = global.Current.Player.entity_copy_source
        -- assert(not cursor)

    end

    local result = get()
    return result
end

function Database:Get(target)
    if target.type == "item" then return self:GetItem(target.name) end
    -- assert()
end

function Database:RefreshTechnology(target) self.Technologies[target.name]:Refresh() end

return Database
