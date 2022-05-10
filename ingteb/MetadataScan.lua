local migration = require "__flib__.migration"
local MetaData = require "lib.MetaData"
local UnusedMetaData = require "ingteb.UnusedMetaData"
local CoreHelper = require "core.Helper"
local Constants = require "Constants"
local Configurations = require("Configurations").Database
local Table = require "core.Table"
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require "core.class"

local Class = class:new("MetadataScan", nil, {})

function Class:new(parent) return self:adopt { Parent = parent } end

function Class:Scan()
    for _, type in pairs { "entity", "fluid", "item", "recipe", "technology" } do
        local key = type .. "_prototypes"
        for name, prototype in pairs(game[key]) do
            dassert(name == prototype.name)
            self:ScanPrototype(type, prototype)
        end
    end
    --dassert(false)
end

function Class:GetBackProxyAny(targetType, targetName, prototype)
    -- dassert(not (targetType == "group" and targetName == "logistics"))
    dassert(type(targetType) == "string")
    dassert(type(targetName) == "string")
    local result = CoreHelper.EnsureKeys(global, { "Game", targetType, targetName })
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
    dassert(type(proxy.Name) == "string")
    local other = self:GetBackProxy(targetType, targetName)
    local backLinks = CoreHelper.EnsureKey(other, propertyName)
    local backLink = { Type = proxy.Type, Name = proxy.Name, Index = index, Proxy = proxy }
    table.insert(backLinks, backLink)
end

function Class:ScanPrototype(targetType, prototype)
    local proxy = self:GetBackProxyRoot(targetType, prototype.name, prototype)

    if (__DebugAdapter and __DebugAdapter.instrument) then
        prototype = self:GetFilteredProxy(prototype)

        local unKnown = Dictionary:new(UnusedMetaData[prototype.object_name])
            :Select(function(_, name) return prototype[name] end)

        dassert(not unKnown:Any())
    end

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
        if options.GetValue then
            self[options.GetValue](self, value, path, proxy, index)
        else
            self:ScanElement(index, value, options, path, proxy)
        end
    end
end

function Class:ScanNamedList(value, options, path, proxy)
    for name, value in pairs(value) do
        self:ScanElement(name, value, options, path, proxy)
    end
end

function Class:ScanElement(key, value, options, path, proxy)
    if not value then return end
    local targetType =
    value ~= true and (CoreHelper.GetObjectType(value)
        or value.type)
        or options.Type
        or value.name
        or value
    dassert(type(targetType) == "string")
    local targetName =
    type(key) == "string" and key
        or options.GetName and options.GetName(value)
        or value.name or value
    dassert(type(targetName) == "string")

    local index = type(key) == "number" and key
    self:SetBackLink(targetType, targetName, path, proxy, index)
end

function Class:GetTechnologyEffect(value, path, proxy, index)
    local targetType = value.type
    self:SetBackLink("effect", targetType, path, proxy, index)
    Dictionary
        :new(value)
        :Select(function(value, name)
            if name == "type" or name == "modifier" then return end
            local targetType = (name == "ammo_category" or name == "recipe") and name
                or name == "turret_id" and "entity"
                or dassert(false)
            self:SetBackLink(targetType, value, path, proxy, index)
        end)
end

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

return Class
