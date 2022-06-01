local migration = require "__flib__.migration"
local MetaData = require "lib.MetaData"
local UnusedMetaData = require "ingteb.UnusedMetaData"
local CoreHelper = require "core.Helper"
local Constants = require "Constants"
local Configurations = require("Configurations").Database
local Helper = require "ingteb.Helper"

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local Table = require "core.Table"
local class = require "core.class"

local Class = class:new("MetadataScan", nil, {})

local function SortByKey(target)
    if type(target) ~= "table"
        or target.DebugPrototype
        or target.Prototype
        or target.Proxy then return target end
    local d = Table:new(target)
    if getmetatable(d) == Array then return target end
    local keys = d:ToArray(function(_, key) return key end)
    table.sort(keys)
    return keys:ToDictionary(function(key)
        return { Key = key, Value = SortByKey(target[key]) }
    end)
end

function Class:Scan()
    if self.IsValid then return end
    self.IsValid = true
    log("Scanning metadata ...")

    global.Game = {}

    Array:new { "entity", "fluid", "item", "recipe", "technology" }
        :Select(function(type)
            Dictionary:new(game[type .. "_prototypes"])
                :Select(function(prototype)
                    self:ScanPrototype(type, prototype)
                end)
        end)

    Dictionary
        :new(Configurations.RecipeDomains)
        :Select(function(setup, name) self:ScanRecipeDomain(name, setup) end)

    if (IsDebugMode) then global.Game = SortByKey(global.Game) end

    log("Scanning metadata complete.")
end

function Class:GetBackProxyAny(targetType, targetName, prototype, debugPrototype)
    dassert(targetType ~= "MiningRecipe" or targetName ~= "accumulator")
    dassert(targetType ~= "item-description.nuclear-fuel")
    dassert(type(targetType) == "string")
    dassert(type(targetName) == "string")

    local result = CoreHelper.EnsureKeys(global.Game, { targetType, targetName })
    CoreHelper.EnsureKey(result, "Type", targetType)
    CoreHelper.EnsureKey(result, "Name", targetName)
    if result.Prototype then
        dassert(not prototype or result.Prototype == prototype)
    else
        result.Prototype = prototype
    end
    if result.DebugPrototype then
        dassert(not debugPrototype or result.DebugPrototype == debugPrototype)
    else
        result.DebugPrototype = debugPrototype
    end

    return result
end

function Class:GetBackProxy(targetType, targetName, getPrototype)
    if getPrototype == false then
        local typeGroup = global.Game[targetType]
        if typeGroup then return typeGroup[targetName] end
        return
    end
    local result = self:GetBackProxyAny(targetType, targetName)
    if getPrototype and not result.Prototype then
        result.Prototype = getPrototype()
    end
    return result
end

function Class:GetBackProxyRoot(targetType, targetName, prototype, debugPrototype)
    if prototype then
        dassert(not prototype.object_name, "Prototype must not be a built-in prototype :" .. (prototype.object_name or "") .. "(" .. (prototype.name or "") .. ")")
    else
        dassert(not IsDebugMode or debugPrototype)
    end
    return self:GetBackProxyAny(targetType, targetName, prototype, debugPrototype)
end

function Class:GetFilteredProxy(prototype)
    if not prototype.object_name then return prototype end
    return Dictionary:new(MetaData[prototype.object_name])
        :Select(function(_, name) return prototype[name] end)
end

function Class:InsertBackLink(targetType, targetName, propertyPath, proxy, index)
    dassert(type(targetType) == "string")
    dassert(type(targetName) == "string")
    dassert(type(proxy.Type) == "string")
    dassert(type(proxy.Name) == "string")
    dassert(index == nil or type(index) == "number")

    local other = self:GetBackProxy(targetType, targetName)
    local backLinks = CoreHelper.EnsureKeys(other, { propertyPath, proxy.Type, proxy.Name })
    CoreHelper.EnsureKey(backLinks, "Proxy", proxy)
    if index then
        CoreHelper.EnsureKey(backLinks, "Indexes")[index] = true
    end
end

function Class:RequiresFluidHandling(proxy)
    local prototype = proxy.Prototype or game[proxy.Type .. "_prototypes"][proxy.Name]
    return prototype.mineable_properties.required_fluid
end

function Class:RequiresNoFluidHandling(proxy) return not self:RequiresFluidHandling(proxy) end

function Class:ScanRecipeDomain(name, setup)
    local domainData = global.Game[setup.GameType]
    if not domainData then
        domainData = self:SetupDomain(name, setup)
    end

    if not global.Game[setup.Recipe.GameType] then
        self:SetupRecipesForDomain(domainData, name, setup)
    end
end

function Class:SetupDomainCategory(setup, categoryName)
    local function GetPrototype()
        local prototypeSetup = setup.Categories[categoryName].Prototype
        if prototypeSetup then
            return game[prototypeSetup.Type .. "_prototypes"][prototypeSetup.Name]
        end
    end

    return self:GetBackProxy(setup.GameType, categoryName, function()
        return Helper.CreatePrototypeProxy
        {
            type = setup.GameType,
            name = categoryName,
            Prototype = GetPrototype(),
            hidden = true,
            Add = { group = false, subgroup = false, },
        }
    end
    )
end

function Class:SetupDomain(name, setup)
    Dictionary:new(setup.Categories)
        :Where(function(value) return value end)
        :Select(function(_, categoryName)
            self:SetupDomainCategory(setup, categoryName)
        end)

    return global.Game[setup.GameType]
end

function Class:SetupRecipesForDomain(domainData, domainName, setup)
    Dictionary:new(domainData)
        :Select(function(category, name)
            self:SetupRecipesForCategory(category, name, domainName, setup)
        end)
end

function Class:SetupRecipesForCategory(category, name, domainName, setup)
    local setup = setup.Recipe
    local primaries = category[setup.BackLinkNamePrimary]
    local primaries = primaries and primaries[setup.Primary]
    if not primaries or not next(primaries) then return end

    local primaries = Dictionary:new(primaries)
    local primaries = setup.Condition == nil and primaries
        or primaries:Where(function(primary) return self[setup.Condition](self, primary.Proxy) end)

    primaries:Select(function(primary)
        local recipe = self:CreatePrototype(domainName, setup, name, primary.Proxy)
        Class:ScanPrototype(setup.GameType, recipe)
    end)
end

function Class:ScanForCategory(domainName, domainSetup, proxy)
    local prototype = proxy.Prototype or game[proxy.Type .. "_prototypes"][proxy.Name]
    local proxySetup = {
        Burning = function()
            local output = prototype.burnt_result
            return {
                Ingredients = { { type = proxy.Type, amount = 1, name = proxy.Name } },
                Products = output and { { type = output.type, amount = 1, name = output.name } } or {},
                Add = { fuel_category = true, fuel_value = true },
            }
        end,
        FluidMining = function()
            local result = { { type = proxy.Type, amount = 1, name = proxy.Name }, }
            local configuration = prototype.mineable_properties
            if (configuration.required_fluid) then
                table.insert(result, { type = "fluid", name = configuration.required_fluid, amount = configuration.fluid_amount, })
            end

            return {
                Ingredients = result,
                Products = configuration.products,
                Energy = configuration.mining_time,
            }
        end,
        Mining = function()
            local configuration = prototype.mineable_properties
            dassert(not configuration.required_fluid)
            return {
                Ingredients = { { type = proxy.Type, amount = 1, name = proxy.Name }, },
                Products = configuration.products,
                Energy = configuration.mining_time,
            }
        end,
    }

    if domainName == "Mining" then
        dassert(not prototype.mineable_properties.required_fluid)
    end

    local setup = proxySetup[domainName]()
    local recipe = Helper.CreatePrototypeProxy
    {
        type = domainSetup.GameType,
        Prototype = prototype,
        Add = setup.Add,
        category = proxy.Name,
        hidden = true,
        sprite_type = proxy.Type,
        energy = setup.Energy,
        ingredients = setup.Ingredients,
        products = setup.Products,
    }

    Class:ScanPrototype(domainSetup.GameType, recipe)
end

function Class:CreatePrototype(domainName, domainSetup, category, proxy)
    local prototype = game[proxy.Type .. "_prototypes"][proxy.Name]
    local proxySetup = {
        Burning = function()
            local output = prototype.burnt_result
            return {
                Ingredients = { { type = proxy.Type, amount = 1, name = proxy.Name } },
                Products = output and { { type = output.type, amount = 1, name = output.name } } or {},
                Add = { fuel_category = true, fuel_value = true },
            }
        end,
        FluidMining = function()
            local ingredients = { { type = proxy.Type, amount = 1, name = proxy.Name }, }
            local configuration = prototype.mineable_properties
            if (configuration.required_fluid) then
                table.insert(ingredients, { type = "fluid", name = configuration.required_fluid, amount = configuration.fluid_amount, })
            end

            return {
                Ingredients = ingredients,
                Products = configuration.products,
                Energy = configuration.mining_time,
            }
        end,
        Mining = function()
            local configuration = prototype.mineable_properties
            dassert(not configuration.required_fluid)
            return {
                Ingredients = { { type = proxy.Type, amount = 1, name = proxy.Name }, },
                Products = configuration.products,
                Energy = configuration.mining_time,
            }
        end,
        HandMining = function()
            local configuration = prototype.mineable_properties
            dassert(not configuration.required_fluid)
            return {
                Ingredients = { { type = proxy.Type, amount = 1, name = proxy.Name }, },
                Products = configuration.products,
                Energy = configuration.mining_time,
            }
        end,
        Boiling = function()
            local fluidBoxes = Array:new(prototype.fluidbox_prototypes)
            local inBox--
            = fluidBoxes--
                :Where(--
                    function(box)
                        return box.filter
                            and (box.production_type == "input" or box.production_type == "input-output")
                    end
                )--
                :Top(false, false)--
                .filter

            local outBox = fluidBoxes--
                :Where(function(box) return box.filter and box.production_type == "output" end)--
                :Top(false, false)--
                .filter

            local inEnergy = (outBox.default_temperature - inBox.default_temperature) * inBox.heat_capacity
            local outEnergy = (prototype.target_temperature - outBox.default_temperature)
                * outBox.heat_capacity

            local amount = 60 * prototype.max_energy_usage / (inEnergy + outEnergy)
            if prototype.burner_prototype and prototype.burner_prototype.effectivity and prototype.burner_prototype.effectivity ~= 1 then
                amount = amount / prototype.burner_prototype.effectivity
            end

            return {
                Ingredients = { { type = "fluid", amount = amount, name = inBox.name } },
                Products = { { type = "fluid", amount = amount, name = outBox.name } },
                Endergy = 1,
            }
        end,
    }

    if domainName == "Mining" then
        dassert(not prototype.mineable_properties.required_fluid)
    end

    local setup = proxySetup[domainName]()
    local recipe = Helper.CreatePrototypeProxy
    {
        type = domainSetup.GameType,
        Prototype = prototype,
        Add = setup.Add,
        category = category,
        hidden = true,
        sprite_type = proxy.Type,
        energy = setup.Energy,
        ingredients = setup.Ingredients,
        products = setup.Products,
    }

    return recipe
end

function Class:IsBurnable(prototype)
    return prototype.fuel_value and prototype.fuel_value > 0
end

function Class:IsHandMineable(prototype)
    local properties = prototype.mineable_properties
    return not prototype.resource_category
        and (not prototype.is_building or prototype.autoplace_specification)
        and properties
        and properties.minable
        and not properties.required_fluid
        and not Array:new(properties.products):Any(function(product) return product.type == "fluid" end)
        and Configurations.ResourceTypes[prototype.type]
end

function Class:ScanRecipeDomainForPrototype(prototype, proxy, domainSetup)
    local workerSetup = domainSetup.Worker
    if workerSetup and workerSetup.EntityType
        and proxy.Type == "entity"
        and workerSetup.EntityType == prototype.type
    then
        Dictionary:new(domainSetup.Categories)
            :Where(function(value) return value end)
            :Select(function(_, categoryName)
                local categoryProxy = self:SetupDomainCategory(domainSetup, categoryName)
                self:InsertBackLink(categoryProxy.Type, categoryProxy.Name, workerSetup.BackLinkPath, proxy)
            end)
    end

    local recipeSetup = domainSetup.Recipe
    if recipeSetup and recipeSetup.Primary == proxy.Type
    then
        Dictionary:new(recipeSetup.Categories)
            :Select(function(setup, categoryName)
                if proxy.Type == "entity" and setup.EntityType and setup.EntityType ~= prototype.type
                    or setup.Condition and not self[setup.Condition](self, prototype)
                then
                    return
                end
                local categoryProxy = self:SetupDomainCategory(domainSetup, categoryName)
                self:InsertBackLink(categoryProxy.Type, categoryProxy.Name, recipeSetup.BackLinkNamePrimary, proxy)
            end)
    end
end

function Class:DebugSetup(prototype)
    local result
    if prototype.object_name then
        dassert(type(prototype.object_name) == "string")

        if IsDebugMode then
            result = { Game = prototype, Filtered = self:GetFilteredProxy(prototype) }

            local unKnown = Dictionary:new(UnusedMetaData[prototype.object_name])
                :Select(function(_, name) return prototype[name] end)

            dassert(not unKnown:Any())
        end
    else
        dassert(not prototype.object_name)
        dassert(type(prototype.object_name_prototype) == "string")
    end
    return result
end

function Class:ScanValues(targetType, prototype, proxy)
    dassert(Configurations.BackLinkMetaData[targetType], "Missing Configurations.BackLinkMetaData for " .. targetType)
    local setup = Configurations.BackLinkMetaData[targetType]
    Dictionary
        :new(setup)
        :Select(function(_, propertyName)
            self:ScanValue(proxy, prototype, propertyName, setup[propertyName])
        end)
end

function Class:CheckBurner(prototype)
    if prototype.object_name == "LuaEntityPrototype"
        and prototype.burner_prototype
        and prototype.burner_prototype.fuel_inventory_size
        and prototype.burner_prototype.fuel_inventory_size <= 0
    then
        log {
            "mod-issue.burner-without-fuel-inventory",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
    end
end

function Class:CheckBoiler(prototype)
    if prototype.object_name ~= "LuaEntityPrototype" or prototype.type ~= "boiler" then
        return
    end

    local fluidBoxes = Array:new(prototype.fluidbox_prototypes)
    if not fluidBoxes then
        log {
            "mod-issue.boiler-without-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    end
    local inBoxes--
    = fluidBoxes--
        :Where(
            function(box)
                return box.production_type == "input" or box.production_type == "input-output"
            end
        ) --
    local outBoxes = fluidBoxes--
        :Where(function(box) return box.production_type == "output" end) --

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

    return true
end

function Class:CheckBurnedResult(prototype)
    if prototype.object_name ~= "LuaItemPrototype" then
        return
    end

    if prototype.burnt_result and not prototype.fuel_category then
        log {
            "mod-issue.burnt-result-without-fuel-category",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
            prototype.burnt_result.localised_name,
            prototype.burnt_result.type .. "." .. prototype.burnt_result.name,
        }
    end

end

function Class:CheckValues(targetType, prototype)
    self:CheckBurner(prototype)
    dassert(self:CheckBoiler(prototype) == self:IsValidBoiler(prototype))
    self:CheckBurnedResult(prototype)
end

function Class:IsValidBoiler(prototype)
    if prototype.object_name ~= "LuaEntityPrototype" or prototype.type ~= "boiler" then
        return
    end

    local fluidBoxes = Array:new(prototype.fluidbox_prototypes)
    if not fluidBoxes then return end
    local inBoxes = fluidBoxes
        :Where(
            function(box)
                return box.production_type == "input" or box.production_type == "input-output"
            end
        ) --
    if not inBoxes or inBoxes:Count() ~= 1 or not inBoxes[1].filter then return end

    local outBoxes = fluidBoxes
        :Where(function(box) return box.production_type == "output" end) --
    if not outBoxes or outBoxes:Count() ~= 1 or not outBoxes[1].filter then return end

    return true
end

function Class:ScanRecipeDomainsForPrototype(prototype, proxy)
    Dictionary
        :new(Configurations.RecipeDomains)
        :Select(function(domainSetup)
            self:ScanRecipeDomainForPrototype(prototype, proxy, domainSetup)
        end)
end

function Class:ScanPrototype(targetType, prototype)
    dassert(type(targetType) == "string")
    dassert(type(prototype.object_name or prototype.object_name_prototype) == "string")

    self:CheckValues(targetType, prototype)

    local prototypeToStore = prototype
    if prototype.object_name then prototypeToStore = nil end -- Only ingteb-created prototypes have to be stored

    local proxy = self:GetBackProxyRoot(targetType, prototype.name, prototypeToStore, self:DebugSetup(prototype))

    self:ScanValues(targetType, prototype, proxy)
    self:ScanRecipeDomainsForPrototype(prototype, proxy)
end

function Class:ScanValue(proxy, prototype, property, setup)
    dassert(type(proxy) == "table")
    dassert(type(prototype.object_name or prototype.object_name_prototype) == "string")
    dassert(type(property) == "string")
    dassert(not setup or type(setup) == "table")
    dassert(prototype.object_name or prototype == proxy.Prototype)

    if setup == false then return end
    local setup = setup == nil and {} or setup

    local function IsList(target)
        if type(target) ~= "table" or #target == 0 and next(target) then
            return false
        elseif not next(target, #target > 0 and #target or nil) then
            return true
        end
    end

    local function ScanElement(key, value, options, path, proxy)
        if options.GetValue then
            return self[options.GetValue](self, key, value, path, proxy)
        end

        if value == nil then return end
        local targetType = options.Type
        if type(value) == "boolean" then
            dassert(options.Type, "Boolean property requires Type in options: " .. serpent.block(options))
        else
            targetType = (CoreHelper.GetObjectType(value) or value.type)
                or targetType
                or value.name
                or value
        end

        dassert(type(targetType) == "string")
        local targetName =
        type(key) == "string" and key
            or options.GetName and options.GetName(value)
            or value.name or value
        dassert(type(targetName) == "string")

        local index = type(key) == "number" and key or nil
        self:InsertBackLink(targetType, targetName, path, proxy, index)
    end

    local function ScanList(value, options, path, proxy)
        for index, value in ipairs(value) do
            ScanElement(index, value, options, path, proxy)
        end
    end

    local function ScanNamedList(value, options, path, proxy)
        for name, value in pairs(value) do
            ScanElement(name, value, options, path, proxy)
        end
    end

    local value = Helper.GetNestedProperty(prototype, { property, setup.Properties })
    if not value then return end

    local path = Helper.GetNestedPath { property, setup.Properties }

    ConditionalBreak(setup.Break, proxy.Type .. "." .. proxy.Name .. "." .. property)

    local valueName = type(value) == "table" and value.name or value

    local valueType
    if type(value) == "string" then
        valueType = setup.Type or property
    elseif type(value) == "table" then
        if value.object_name then
            valueType = CoreHelper.GetObjectType(value)
        elseif value.object_name_prototype then
            valueType = setup.Type or prototype.type
        end
    else return end

    if valueType then
        self:InsertBackLink(valueType, valueName, property, proxy)
    elseif IsList(value) then
        ScanList(value, setup, path, proxy)
    elseif setup.IsList then
        ScanNamedList(value, setup, path, proxy)
    else
        ScanElement(nil, value, setup, path, proxy)
    end
end

function Class:GetTechnologyEffect(key, value, path, proxy)
    local targetType = value.type
    self:InsertBackLink("effect", targetType, path, proxy, key)
    Dictionary
        :new(value)
        :Select(function(value, name)
            if name == "type" or name == "modifier" then return end
            local targetType = (name == "ammo_category" or name == "recipe") and name
                or name == "turret_id" and "entity"
                or dassert(false)
            self:InsertBackLink(targetType, value, path, proxy, key)
        end)
end

return Class
