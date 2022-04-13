require "core.debugSupport"
local class = {name = "class"}

local function GetInherited(self, key)
    if not self then return end
    return self.system.Properties[key] or GetInherited(self.system.BaseClass, key)
end

local function GetField(self, key, classInstance)
    local accessors = classInstance.system.Properties[key]
    if accessors then
        if accessors.cache then
            return self.cache[accessors.class][key].Value
        else
            return accessors.get(self)
        end
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
--- @param base table class the base class - optional
--- @param properties table initial properties - optional
--- @return table class new class 
function class:new(name, base, properties)
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
    local classInstance = {system = systemValues, name = name, class = class}

    function metatable:__index(key)
        local result = GetField(self, key, classInstance)
        return result
    end

    function metatable:__newindex(key, value)
        local accessors = classInstance.system.Properties[key]
        if accessors then
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
    function classInstance:adopt(instance, isMinimal)
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
            for key, value in pairs(self.system.Properties) do
                value.class = self.name
                local inherited = GetInherited(self.system.BaseClass, key)
                if inherited then
                    if not rawget(instance, "inherited") then
                        instance.inherited = {}
                    end
                    if not instance.inherited[self.name] then
                        instance.inherited[self.name] = {}
                    end
                    instance.inherited[self.name][key] = inherited
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
                local result --
                = name .. "{" --
                .. (base and "BaseClass=" .. base.system.Name .. "," or "") --
                .. "}"
                return result
            end,
        }
    )

    return classInstance
end

function class:__debugline() return self.system.Name end

return class
