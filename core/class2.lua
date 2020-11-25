local class = {}

function class:new(name, super)
    local result = {name = name, metatable = {}, property = {}}

    local metatable = result.metatable

    function metatable:__index(key)
        local accessors = result.property[key]
        if accessors then
            return accessors.get(self)
        elseif result[key] ~= nil then
            return result[key]
        elseif super then
            return super.metatable.__index(self, key)
        else
            return nil
        end
    end

    function metatable:__newindex(key, value)
        local accessors = result.property[key]
        if accessors then
            return accessors.set(self, value)
        elseif super then
            return super.metatable.__newindex(self, key, value)
        else
            rawset(self, key, value)
        end
    end

    function result:adopt(instance)
        return setmetatable(instance, self.metatable)
    end

    return result
end

return class
