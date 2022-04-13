local class = require("core.classclass")
local ValueCache = require "core.ValueCache"
local PlayerValueCache = require "core.PlayerValueCache"

--- installs the cache for a cached property
--- @param instance table will be patched to contain metatable, property, inherited and cache , if required
--- @param classInstance table
--- @param name string then property name
--- @param getter function the function that calulates the actual value
--- @param isCacheTypePlayer boolean when set the cache will be player specific. In that case instance should define a property Player
function class.addCachedProperty(instance, classInstance, name, getter, isCacheTypePlayer)
    local className = classInstance.system.Name
    if not rawget(instance, "cache") then rawset(instance, "cache", {}) end
    if not instance.cache[className] then instance.cache[className] = {} end
    instance.cache[className][name] = --
    isCacheTypePlayer and PlayerValueCache:new(instance, getter) or --
    ValueCache:new(instance, getter)
end

return class
