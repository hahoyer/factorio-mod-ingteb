local Dictionary = {}


function Dictionary:Clone(predicate)
    local result = Dictionary:new {}
    for key, value in pairs(self) do
        if not predicate or predicate(value, key) then result[key] = value end
    end
    return result
end

function Dictionary:Where(predicate) return self:Clone(predicate) end

function Dictionary:Except(other) return self:Where(function(_, key) return not other[key] end) end

function Dictionary:new(target)
    if not target then target = {} end
    self.object_name = "Dictionary"
    if getmetatable(target) == "private" then target = Dictionary.Clone(target) end
    setmetatable(target, self)
    self.__index = self
    return target
end

function Dictionary:Select(transformation)
    local result = Dictionary:new {}
    for key, value in pairs(self) do result[key] = transformation(value, key) end
    return result
end

function Dictionary:Sum(predicate)
    local result = 0
    for key, value in pairs(self) do
        if not predicate or predicate(value, key) then result = result + value end
    end
    return result
end

function Dictionary:Maximum(selector)
    local result
    if not selector then selector = function(value) return value end end
    for key, value in pairs(self) do
        if not result or selector(result) < selector(value) then result = value end
    end
    return result
end

function Dictionary:Minimum(selector)
    local result
    if not selector then selector = function(value) return value end end
    for key, value in pairs(self) do
        if not result or selector(result) > selector(value) then result = value end
    end
    return result
end

function Dictionary:Count(predicate)
    local result = 0
    for key, value in pairs(self) do
        if not predicate or predicate(value, key) then result = result + 1 end
    end
    return result
end

function Dictionary:All(predicate)
    for key, value in pairs(self) do if not predicate(value, key) then return false end end
    return true
end

function Dictionary:Any(predicate)
    for key, value in pairs(self) do
        if not predicate or predicate(value, key) then return true end
    end
    return nil
end

function Dictionary:ToDictionary(getPair)
    local result = Dictionary:new {}
    for key, value in pairs(self) do
        if getPair then
            local pair = getPair(value, key)
            result[pair.Key] = pair.Value
        else
            result[key] = value
        end
    end
    return result
end

function Dictionary:ToGroup(getPair)
    local result = Dictionary:new {}
    for key, value in pairs(self) do
        if getPair then
            local pair = getPair(value, key)
            local current = result[pair.Key] or Array:new {}
            current:Append(pair.Value)
            result[pair.Key] = current
        else
            local current = result[key] or Array:new {}
            current:Append(value)
            result[key] = current
        end
    end
    return result
end

function Dictionary:ToArray(getItem)
    local result = Array:new {}
    if not getItem then getItem = function(value) return value end end
    for key, value in pairs(self) do result:Append(getItem(value, key)) end
    return result
end

--- Get the first element
---@param allowEmpty boolean optional default: true
---@param allowMultiple boolean optional default: true
---@param onEmpty any error message function, opional
---@param onMultiple any error message function, opional
function Dictionary:Top(allowEmpty, allowMultiple, onEmpty, onMultiple)
    local result
    for key, value in pairs(self) do
        if allowMultiple ~= false then return { Key = key, Value = value } end
        if result then
            error(onMultiple and onMultiple(#self) or "Dictionary contains more than one element (" ..
                #self .. ").", 1)
        end
        result = { Key = key, Value = value }
    end

    if result then return result end

    if allowEmpty == false or onEmpty then
        error(onEmpty and onEmpty() or "Dictionary contains no element.", 1)
    end
end

function Dictionary:Aggregate(combinator)
    local result
    for key, value in pairs(self) do result = combinator(result, value, key) end
    return result
end

function Dictionary:Concat(other, combine)
    if not self:Any() then return other end
    if not other:Any() then return self end

    local result = self:Clone()
    for key, value in pairs(other) do
        result[key] = result[key] and combine(result[key], value, key) or value
    end
    return result
end

function Dictionary:AppendForKey(key, target)
    if key then
        local list = self[key]
        if not list then self[key] = Array:new() end
        self[key]:Append(target)
    end
end

function Dictionary:AppendMany(values, combine)
    for key, value in pairs(values) do
        self[key] = self[key] and combine and combine(self[key], value, key) or value
    end
end

return Dicionary
