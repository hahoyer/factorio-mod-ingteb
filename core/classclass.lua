require "core.debugSupport"
local class = { name = "class" }

local function GetInherited(self, key)
    if not self then return end
    return self.system.Properties[key] or GetInherited(self.system.BaseClass, key)
end

local function GetProperty(self, key, classInstance, property)
    local classCache = self.system.Cache and self.system.Cache[property.class]
    if classCache then
        local cache = classCache[key]
        if cache then return cache.Value end
    end
    local get = property.get
    dassert(get, "Property '" .. key .. "' of class '" .. classInstance.name .. "' has no getter")
    return get(self)
end

local function GetField(self, key, classInstance)
    local property = classInstance.system.Properties[key]
    if property then
        local result = GetProperty(self, key, classInstance, property)
        if __DebugAdapter then
            if not rawget(self, "system") then rawset(self, "system", {}) end
            if not rawget(self.system, "LastValue") then rawset(self.system, "LastValue", {}) end
            if not self.system.LastValue[classInstance.name] then self.system.LastValue[classInstance.name] = {} end
            self.system.LastValue[classInstance.name][key] = result or "nil"
        end
        return result
    elseif rawget(classInstance, key) ~= nil then
        return classInstance[key]
    end

    local base = classInstance.system.BaseClass
    if base then
        return base.system.Metatable.__index(self, key)
    else
        return nil
    end
end

-- if __DebugAdapter then __DebugAdapter.stepIgnore(GetField) end

--- Defines a class
--- @param name string the name of the class
--- @param base table class the base class
--- @param properties table initial properties
--- @return table class new class
function class:new(name, --[[optional]] base, --[[optional]] properties)
    dassert(type(name) == "string")
    if base then
        dassert(base.class == class)
        dassert(
            not base.system.InstantiationType --
            or base.system.InstantiationType == "Base", --
            name .. ": class " .. base.system.Name .. " cannot be used as base class."
        )
    end

    local metatable = {}
    local systemValues = {
        Name = name,
        Metatable = metatable,
        BaseClass = base,
        Properties = properties or {},
    }
    local classInstance = { system = systemValues, name = name, class = class }

    function metatable:__index(key)
        local result = GetField(self, key, classInstance)
        return result
    end

    function metatable:__newindex(key, value)
        local accessors = classInstance.system.Properties[key]
        if accessors then
            dassert(accessors.set, "Property '" .. key .. "' of class '" .. classInstance.name .. "' has no setter")
            return accessors.set(self, value)
        elseif base then
            return base.system.Metatable.__newindex(self, key, value)
        else
            rawset(self, key, value)
        end
    end

    if GetInherited(classInstance, "DebugLine") then
        function metatable:__debugline() return self.DebugLine end
    end

    if __DebugAdapter then __DebugAdapter.stepIgnore(metatable.__newindex) end

    --- "Adopts" any table as instance of a class by providing metatable and property setup
    --- @param instance table will be patched to contain metatable, property, inherited and cache , if required
    --- @param isMinimal boolean (optional) do change anything. For use in on_load.
    --- @return table instance ... but patched
    function classInstance:adopt(instance, --[[optional]] isMinimal)
        if not instance then instance = {} end
        if self.system.InstantiationType == "Singleton" and self.system.Instance then
            dassert(
                self.system.Instance == instance,
                "Class " .. self.system.Name .. " has been intantiated already."
            )
            return instance
        end
        dassert(
            self.system.InstantiationType ~= "Base",
            "Instances of class " .. self.system.Name .. " are not allowed."
        )

        if not isMinimal then instance.class = self end
        setmetatable(instance, self.system.Metatable)
        if not isMinimal then
            if not rawget(instance, "system") then rawset(instance, "system", {}) end

            for key, value in pairs(self.system.Properties) do
                value.class = self.name
                local inherited = GetInherited(self.system.BaseClass, key)
                if inherited then
                    if not rawget(instance.system, "Inherited") then
                        instance.system.Inherited = {}
                    end
                    if not instance.system.Inherited[self.name] then
                        instance.system.Inherited[self.name] = {}
                    end
                    instance.system.Inherited[self.name][key] = inherited
                end
                if value.cache then
                    dassert(not value.set)
                    dassert(
                        value.cache == true or value.cache == "player", "invalid cache setting: "
                        .. tostring(value.cache) .. ". Must true, false or 'player'"
                    )
                    class.addCachedProperty(instance, self, key, value.get, value.cache == "player")
                end
            end
        end
        if self.system.InstantiationType == "Singleton" then self.system.Instance = instance end
        return instance
    end

    setmetatable(
        classInstance, {
        __debugline = function(self)
            local result--
            = name .. "{" --
                .. (base and "BaseClass=" .. base.system.Name .. "," or "") --
                .. "}"
            return result
        end,
    }
    )

    classInstance.getCache = function(self, instance, targetClass)
        if instance.cache then
            return instance.cache[targetClass or self.class.name]
        end
    end

    return classInstance
end

function class:__debugline() return self.system.Name end

return class
