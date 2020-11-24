local PropertyProvider = require("core.PropertyProvider")
local ValueCacheContainer = require("core.ValueCacheContainer")

local Class = {object_name = "Class"}

function Class:new(target)
    local result = ValueCacheContainer:new(target)

    function result:properties(list)
        for key, value in pairs(list) do
            if value.cache then
                self:addCachedProperty(key, value.get)
            else
                self.property[key] = {get = value.get, set = value.set}
            end

        end
    end

    return result

end

return Class
