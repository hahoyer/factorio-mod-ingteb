local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary

local function SpreadHandMiningRecipe(prototype)
    local inList = {{type = prototype.type, name = prototype.name}}
    if prototype.mineable_properties.required_fluid then
        table.insert(inList, {type = "fluid", name = prototype.mineable_properties.required_fluid})
    end

    return {
        In = Array:new(inList),
        Properties = Array:new {
            {
                type = "utility",
                name = "clock",
                amount = prototype.mineable_properties.mining_time
            }
        },
        Out = Array:new(prototype.mineable_properties.products)
    }
end

local function GetAmountForRecipe(target)
    if not target.enabled then
        return
    end

    local result = global.Current.Player.get_craftable_count(target.name)
    if result > 0 then
        return result
    end
end

local function GetAmountForTecnology(target)
    if target and target.level and target.prototype.max_level > 1 then
        return target.level
    end
end

local function SpreadRecipe(recipe)
    local technology =
        Dictionary:new(global.Current.Player.force.technologies):Where(
        function(technology)
            return Array:new(technology.effects):Any(
                function(effect)
                    return effect.type == "unlock-recipe" and effect.recipe == recipe.name
                end
            )
        end
    ):Top(true, true)

    local hasPrerequisites =
        technology and
        Dictionary:new(technology.prerequisites):Where(
            function(pre)
                return not pre.researched
            end
        ):Any()
    return {
        In = Array:new(recipe.ingredients),
        Properties = Array:new {
            {
                type = "technology",
                name = technology and technology.name,
                hasPrerequisites = hasPrerequisites,
                amount = GetAmountForTecnology(technology),
                cache = {Prototype = {Value = technology}}
            },
            {
                type = "recipe",
                name = recipe.name,
                amount = GetAmountForRecipe(recipe),
                cache = {Prototype = {Value = recipe}}
            },
            {
                type = "utility",
                name = "clock",
                amount = recipe.energy
            }
        },
        Out = Array:new(recipe.products)
    }
end

local function SpreadMiningActors(prototype)
    local modifier = global.Current.Player.character_mining_speed_modifier
    if modifier == 0 then
        modifier = nil
    end

    local key = prototype.resource_category
    local hasFluid = prototype.mineable_properties.fluid_amount and prototype.mineable_properties.fluid_amount > 0

    local result =
        Dictionary:new(game.entity_prototypes):Where(
        function(entity)
            if hasFluid and #entity.fluidbox_prototypes == 0 then
                return false
            end
            return entity.resource_categories and entity.resource_categories[key]
        end
    ):ToArray():Select(
        function(entity)
            local target = {
                name = entity.name,
                type = "entity",
                amount = entity.mining_speed,
                cache = {Prototype = {Value = entity}}
            }
            return target
        end
    )
    if hasFluid then
        return result
    end
    return result:Concat(Array:new {{type = "tool", name = "steel-axe", amount = modifier}})
end

local function SpreadHandMining(target)
    local prototype = game.entity_prototypes[target.name]

    if prototype.mineable_properties.minable then
        return {
            Actors = SpreadMiningActors(prototype),
            Recipes = Array:new {SpreadHandMiningRecipe(prototype)}
        }
    end
end

local function SpreadResource(target)
    local groups = Table.Array:new {}
    local handMining = SpreadHandMining(target)
    if handMining then
        groups:Append(handMining)
    end

    return {Target = target, In = groups, Out = Array:new {}}
end

local function SpreadActors(key)
    return Dictionary:new(game.entity_prototypes):Where(
        function(entity)
            return entity.crafting_categories and entity.crafting_categories[key]
        end
    ):ToArray():Select(
        function(entity)
            local target = {name = entity.name, type = "entity", amount = entity.crafting_speed}
            return target
        end
    )
end

local function SpreadItemGroup(target, key)
    local actors = SpreadActors(key)
    local recipes =
        target:Select(
        function(recipe)
            return SpreadRecipe(recipe)
        end
    )
    recipes:Sort(
        function(a, b)
            if a == b then
                return false
            end

            local aRecipe = a.Properties[2].cache.Prototype.Value
            local bRecipe = b.Properties[2].cache.Prototype.Value

            if aRecipe.enabled ~= bRecipe.enabled then
                return aRecipe.enabled
            end

            local aTechnology = a.Properties[1].cache.Prototype.Value
            local bTechnology = b.Properties[1].cache.Prototype.Value

            if (not aTechnology) ~= (not bTechnology) then
                return not aTechnology
            end

            if aTechnology and aTechnology.researched ~= bTechnology.researched then
                return aTechnology.researched
            end

            if (not a.Properties[1].hasPrerequisites) ~= (not b.Properties[1].hasPrerequisites) then
                return not a.Properties[1].hasPrerequisites
            end

            if aRecipe.group ~= bRecipe.group then
                return aRecipe.group.order < bRecipe.group.order
            end
            if aRecipe.subgroup ~= bRecipe.subgroup then
                return aRecipe.subgroup.order < bRecipe.subgroup.order
            end

            return aRecipe.order < bRecipe.order
        end
    )

    return {Actors = actors, Recipes = recipes}
end

local function SpreadItemIn(target)
    return Dictionary:new(global.Current.Player.force.recipes):Where(
        function(recipe)
            if recipe.hidden then
                return false
            end
            return Array:new(recipe.ingredients):Any(
                function(this)
                    return this.name == target.name and this.type == target.type
                end
            )
        end
    ):ToArray():ToGroup(
        function(recipe)
            return {Key = recipe.category, Value = recipe}
        end
    ):Select(
        function(group, key)
            return SpreadItemGroup(group, key)
        end
    )
end

local function SpreadItemOut(target)
    return Dictionary:new(global.Current.Player.force.recipes):Where(
        function(item)
            return Array:new(item.products):Any(
                function(this)
                    return this.name == target.name and this.type == target.type
                end
            )
        end
    ):ToArray():ToGroup(
        function(recipe)
            return {Key = recipe.category, Value = recipe}
        end
    ):Select(
        function(group, key)
            return SpreadItemGroup(group, key)
        end
    )
end

local function SpreadItemWork(target)
    local prototype = Helper.GetFactorioData(target)
    if not prototype or prototype.type ~= "item" then
        return
    end
    local entity = prototype.place_result
    if not entity or not entity.crafting_categories then
        return
    end


    local x = y/z
end

local function SpreadItem(target)
    return {Target = target, Work = SpreadItemWork(target), In = SpreadItemIn(target), Out = SpreadItemOut(target)}
end

local function SpreadEntity(target)
    local entity = game.entity_prototypes[target.name]
    if not entity then
        return
    end
    local candidates = entity.items_to_place_this
    if not candidates or #candidates == 0 then
        return
    end
    local item = candidates[1]
    return SpreadItem({type = "item", name = item.name})
end

local function ProvideHelp(target)
    local result
    if target.type == "technology" or target.type == "recipe" then
        return
    end
    if target.type == "resource" or target.type == "fish" or target.type == "tree" or target.type == "simple-entity" then
        result = SpreadResource(target)
    elseif target.type == "item" or target.type == "fluid" then
        result = SpreadItem(target)
    else
        result = SpreadEntity(target)
    end
    if not result then
        target.type = "item"
        result = SpreadItem(target)
    end
    return result
end

local function ProvideResearch(technologyName)
end

local function ProvideCrafting(recipeName)
end

local result = {}

function result.Get(target)
    if target.type == "item-entity" and target.name == "item-on-ground" then
        return
    end
    if not target.target then
        return ProvideHelp(target)
    end
    local subTarget = target.target
    if target.name and not target.amount then
        return ProvideResearch(target.name)
    end
    if target.amount and target.amout > 0 then
        return ProvideCrafting(subTarget.name)
    end
end

function result.FindTarget()
    local result = {}

    local cursor = global.Current.Player.cursor_stack
    if cursor and cursor.valid and cursor.valid_for_read then
        return {type = cursor.type, name = cursor.name}
    end
    local cursor = global.Current.Player.cursor_ghost
    if cursor then
        return {type = cursor.type, name = cursor.name}
    end
    local cursor = global.Current.Player.selected
    if cursor then
        return {type = cursor.type, name = cursor.name}
    end

    local cursor = global.Current.Player.opened
    if cursor then
        if global.Current.Links and global.Current.Links[cursor.index] then
            local target = global.Current.Links[cursor.index]
            return target
        end
        table.insert(result, {type = cursor.type, name = cursor.name})
        if cursor.burner then
            return {fuel_categories = cursor.burner.fuel_categories}
        end
        if cursor.type == "mining-drill" and cursor.mining_target then
            return {type = cursor.mining_target.type, name = cursor.mining_target.name}
        end

        if cursor.type == "furnace" and cursor.previous_recipe then
            return {type = "recipe", name = cursor.previous_recipe.name}
        end
        if cursor.type == "assembling-machine" and cursor.get_recipe() then
            return {type = "recipe", name = cursor.get_recipe().name}
        end
    end
end

return result
