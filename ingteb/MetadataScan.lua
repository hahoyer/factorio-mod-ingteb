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

    for _, type in pairs { "entity", "fluid", "item", "recipe", "technology" } do
        local key = type .. "_prototypes"
        for _, prototype in pairs(game[key]) do
            self:ScanPrototype(type, prototype)
        end
    end
    if (IsDebugMode) then global.Game = SortByKey(global.Game) end

    log("Scanning metadata complete.")
end

function Class:GetBackProxyAny(targetType, targetName, prototype, debugPrototype)
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

function Class:GetBackProxy(targetType, targetName)
    return self:GetBackProxyAny(targetType, targetName)
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

function Class:InsertBackLink(targetType, targetName, propertyName, proxy, index)
    local other = self:GetBackProxy(targetType, targetName)
    local backLinks = CoreHelper.EnsureKeys(other, { propertyName, proxy.Type, proxy.Name })
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

function Class:ScanForCategories(targetType, targetName, propertyName, proxy)
    Dictionary
        :new(Configurations.RecipeDomains)
        :Where(function(domainSetup)
            if domainSetup.BackLinkType == targetType
                and domainSetup.BackLinkTypeRecipe
                and domainSetup.RecipeInitiatingProperty == propertyName
            then
                local backLinks = global.Game[domainSetup.BackLinkTypeRecipe]
                if backLinks and backLinks[proxy.Name] then return end
                if domainSetup.Condition then
                    return self[domainSetup.Condition](self, proxy)
                end
                return true
            end
        end)
        :Select(function(domainSetup, domainName)
            self:ScanForCategory(domainName, domainSetup, targetName, propertyName, proxy)
        end)
end

function Class:ScanForCategory(domainName, domainSetup, targetName, propertyName, proxy)
    local prototype = proxy.Prototype or game[proxy.Type .. "_prototypes"][proxy.Name]
    local proxySetup = {
        Burning = function()
            local output = prototype.burnt_result
            return {
                Ingredients = { { type = proxy.Type, amount = 1, name = proxy.Name } },
                Products = output and { { type = output.type, amount = 1, name = output.name } } or {},
                Also = { "fuel_category", "fuel_value" },
            }
        end,
        FluidMining = function()
            local result = { { type = "resource", amount = 1, name = proxy.Name }, }
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
                Ingredients = { { type = "resource", amount = 1, name = proxy.Name }, },
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
        type = domainSetup.BackLinkTypeRecipe,
        Prototype = prototype,
        Also = setup.Also,
        category = targetName,
        hidden = true,
        sprite_type = proxy.Type,
        energy = setup.Energy,
        ingredients = setup.Ingredients,
        products = setup.Products,
    }

    Class:ScanPrototype(domainSetup.BackLinkTypeRecipe, recipe)
end

function Class:SetBackLink(targetType, targetName, propertyName, proxy, index)
    dassert(type(proxy.Type) == "string")
    dassert(type(proxy.Type) == "string")
    dassert(type(proxy.Name) == "string")
    self:InsertBackLink(targetType, targetName, propertyName, proxy, index)
    self:ScanForCategories(targetType, targetName, propertyName, proxy)
end

function Class:ScanPrototype(targetType, prototype)
    dassert(type(targetType) == "string")
    local debugPrototype
    if prototype.object_name then
        dassert(type(prototype.object_name) == "string")

        if IsDebugMode then
            debugPrototype = { Game = prototype, Filtered = self:GetFilteredProxy(prototype) }

            local unKnown = Dictionary:new(UnusedMetaData[prototype.object_name])
                :Select(function(_, name) return prototype[name] end)

            dassert(not unKnown:Any())
        end
    else
        dassert(not prototype.object_name)
        dassert(type(prototype.object_name_prototype) == "string")
    end

    local proxy = self:GetBackProxyRoot(targetType, prototype.name, not prototype.object_name and prototype or nil, debugPrototype)

    dassert(Configurations.BackLinkMetaData[targetType], "Missing Configurations.BackLinkMetaData for " .. targetType)
    local setup = Configurations.BackLinkMetaData[targetType]
    Dictionary
        :new(setup)
        :Select(function(_, propertyName) self:ScanValue(proxy, prototype, propertyName, setup[propertyName]) end)
end

function Class:ScanValue(proxy, prototype, property, setup)
    if setup == false then return end
    local setup = setup == nil and {} or setup
    dassert(type(proxy) == "table")
    dassert(type(prototype.object_name or prototype.object_name_prototype) == "string")
    dassert(type(property) == "string")
    dassert(type(setup) == "table")
    dassert(prototype.object_name or prototype == proxy.Prototype)

    local function GetPathAndValue(prototype, property, options)
        local value = prototype[property]
        if not value then return end
        local path = property
        if options.Properties then
            for _, property in ipairs(options.Properties) do
                path = path .. "." .. property
                value = value[property]
                if not value then return end
            end
        end
        return path, value
    end

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

        local index = type(key) == "number" and key
        self:SetBackLink(targetType, targetName, path, proxy, index)
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

    local path, value = GetPathAndValue(prototype, property, setup)
    if not value then return end

    ConditionalBreak(setup.Break, proxy.Type .. "." .. proxy.Name .. "." .. property)
    local valueType
    local valueName
    if type(value) == "string" then
        valueType = setup.Type or property
        valueName = value
    elseif type(value) ~= "table" then
        return
    elseif value.object_name then
        valueType = value.object_name and CoreHelper.GetObjectType(value) or nil
        valueName = value.name
    elseif value.object_name_prototype then
        valueType = setup.Type or prototype.type
        valueName = value.name
    end

    if valueType then
        self:SetBackLink(valueType, valueName, property, proxy)
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
    self:SetBackLink("effect", targetType, path, proxy, key)
    Dictionary
        :new(value)
        :Select(function(value, name)
            if name == "type" or name == "modifier" then return end
            local targetType = (name == "ammo_category" or name == "recipe") and name
                or name == "turret_id" and "entity"
                or dassert(false)
            self:SetBackLink(targetType, value, path, proxy, key)
        end)
end

return Class
