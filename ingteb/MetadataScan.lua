local migration = require "__flib__.migration"
local MetaData = require "lib.MetaData"
local UnusedMetaData = require "ingteb.UnusedMetaData"
local CoreHelper = require "core.Helper"
local Constants = require "Constants"
local Configurations = require("Configurations").Database

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local Table = require "core.Table"
local class = require "core.class"

local Class = class:new("MetadataScan", nil, {})

local function SortByKey(target)
    if type(target) ~= "table" then return target end
    local d = Table:new(target)
    if getmetatable(d) == Array then return target end
    local keys = d:ToArray(function(_, key) return key end)
    table.sort(keys)
    return keys:ToDictionary(function(key)
        return { Key = key, Value = SortByKey(target[key]) }
    end)
end

function Class:Scan()
    global.Game = {}

    for _, type in pairs { "entity", "fluid", "item", "recipe", "technology" } do
        local key = type .. "_prototypes"
        for name, prototype in pairs(game[key]) do
            dassert(name == prototype.name)
            self:ScanPrototype(type, prototype)
        end
    end
    if (__DebugAdapter and __DebugAdapter.instrument) then global.Game = SortByKey(global.Game) end
end

function Class:GetBackProxyAny(targetType, targetName, prototype)
    dassert(not (targetType == "category" and targetName ~= "slogistics"))
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

    return result
end

function Class:GetBackProxy(targetType, targetName)
    return self:GetBackProxyAny(targetType, targetName)
end

function Class:GetBackProxyRoot(targetType, targetName, prototype)
    dassert(prototype)
    return self:GetBackProxyAny(targetType, targetName, prototype)
end

function Class:GetFilteredProxy(prototype)
    return Dictionary:new(MetaData[prototype.object_name])
        :Select(function(_, name) return prototype[name] end)
end

function Class:SetBackLink(targetType, targetName, propertyName, proxy, index)
    dassert(type(proxy.Type) == "string")
    dassert(type(proxy.Type) == "string")
    dassert(type(proxy.Name) == "string")
    local other = self:GetBackProxy(targetType, targetName)
    local backLinks = CoreHelper.EnsureKeys(other, { propertyName, proxy.Type, proxy.Name })
    local backLink = { Index = index, Proxy = proxy }
    table.insert(backLinks, backLink)
end

function Class:ScanPrototype(targetType, prototype)
    if (__DebugAdapter and __DebugAdapter.instrument) then
        prototype = self:GetFilteredProxy(prototype)

        local unKnown = Dictionary:new(UnusedMetaData[prototype.object_name])
            :Select(function(_, name) return prototype[name] end)

        dassert(not unKnown:Any())
    end

    local proxy = self:GetBackProxyRoot(targetType, prototype.name, prototype)

    return Dictionary
        :new(Configurations.BackLinkMetaData[prototype.object_name])
        :Select(function(options, propertyName) self:ScanValue(proxy, prototype, propertyName, options) end)
end

function Class:ScanValue(proxy, prototype, property, options)
    dassert(type(proxy) == "table")
    dassert(type(prototype.object_name) == "string")
    dassert(type(property) == "string")
    dassert(type(options) == "table")

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

    local path, value = GetPathAndValue(prototype, property, options)
    if not value then return end

    local valueType = CoreHelper.GetObjectType(value)
    if valueType then
        self:SetBackLink(valueType, value.name or value, property, proxy)
    elseif IsList(value) then
        self:ScanList(value, options, path, proxy)
    elseif type(value) == "table" and options.IsList then
        self:ScanNamedList(value, options, path, proxy)
    elseif type(value) == "table" then
        self:ScanElement(nil, value, options, path, proxy)
    elseif type(value) == "string" then
        self:SetBackLink(options.Type or property, value, path, proxy)
    else
        dassert(false)
    end
end

function Class:ScanList(value, options, path, proxy)
    for index, value in ipairs(value) do
        self:ScanElement(index, value, options, path, proxy)
    end
end

function Class:ScanNamedList(value, options, path, proxy)
    for name, value in pairs(value) do
        self:ScanElement(name, value, options, path, proxy)
    end
end

function Class:ScanElement(key, value, options, path, proxy)
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
