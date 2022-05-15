local TableNew = require "core.TableNew"
local Dictionary = TableNew.Dictionary
local Array = TableNew.Array

function Array:Where(predicate) return self:Clone(predicate) end

function Array:Sort(order) table.sort(self, order) end

function Array:Intersection(other)
    return other:Where(function(entry) return self:Contains(entry) end)
end

function Array:Union(other)
    return self:Concat(other:Where(function(entry) return not self:Contains(entry) end))
end

function Array:Except(other) return self:Where(function(entry) return not other:Contains(entry) end) end

function Array:IntersectMany()
    if not self:Any() then return Array:new {} end
    local result = self[1]
    for index = 2, #self do result = result:Intersection(self[index]) end
    return result
end

function Array:UnionMany()
    if not self:Any() then return Array:new {} end
    local result = self[1]
    for index = 2, #self do result = result:Union(self[index]) end
    return result
end

function Array:FromNumber(number)
    local target = Array:new()
    for index = 1, number do target:Append(index) end
    return target
end

function Array:Select(transformation)
    local result = Array:new {}
    for index = 1, #self do
        if self[index] then result:Append(transformation(self[index], index)) end
    end
    return result
end

function Array:Compact()
    local result = Array:new {}
    for index = 1, #self do if self[index] then result:Append(self[index]) end end
    return result
end

function Array:Strip(doNotCompact)
    local result = {}
    for index = 1, #self do
        if doNotCompact or self[index] then table.insert(result, self[index]) end
    end
    return result
end

function Array:Sum(predicate)
    local result = 0
    for key, value in ipairs(self) do
        if not predicate or predicate(value, key) then result = result + value end
    end
    return result
end

function Array:Maximum(selector)
    local result
    if not selector then selector = function(value) return value end end
    for key, value in ipairs(self) do
        if not result or selector(result) < selector(value) then result = value end
    end
    return result
end

function Array:Minimum(selector)
    local result
    if not selector then selector = function(value) return value end end
    for key, value in ipairs(self) do
        if not result or selector(result) > selector(value) then result = value end
    end
    return result
end

function Array:IndexWhere(predicate, start)
    if not start then start = 1 end
    for index = start, #self do if predicate(self[index], index) then return index end end
end

function Array:Count(predicate)
    if not predicate then return #self end
    local result = 0
    for index = 1, #self do
        local value = self[index]
        if predicate(value, index) then result = result + 1 end
    end
    return result
end

function Array:All(predicate)
    for index = 1, #self do
        local value = self[index]
        if not predicate(value, index) then return false end
    end
    return true
end

function Array:Any(predicate)
    for index = 1, #self do
        local value = self[index]
        if not predicate or predicate(value, index) then return true end
    end
    return nil
end

function Array:Contains(item)
    for index = 1, #self do
        local value = self[index]
        if value == item then return true end
    end
    return nil
end

function Array:GetUniqueEntries(predicate)
    local result = self:ToDictionary(function(value)
        return { Key = predicate(value), Value = value }
    end):ToArray(function(value) return value end)
    return result
end

function Array:GetIndexOfShortest()
    if not self:Any() then return 0 end

    local result = 1

    local count = self[1]:Count()
    for index = 2, self:Count() do
        local iresult = self[index]
        if count < iresult:Count() then
            result = index
            count = iresult:Count()
        end
    end
    return result
end

function Array:GetShortest()
    local index = self:GetIndexOfShortest()
    return self[index]
end

function Array:ToArray(getItem)
    local result = Array:new {}
    if not getItem then getItem = function(value) return value end end
    for index = 1, #self do
        local value = self[index]
        result:Append(getItem(value))
    end
    return result
end

--- Get the first element
---@param allowEmpty boolean optional default: true
---@param allowMultiple boolean optional default: true
---@param onEmpty any error message function, opional
---@param onMultiple any error message function, opional
function Array:Top(allowEmpty, allowMultiple, onEmpty, onMultiple)
    if #self == 0 then
        if allowEmpty == false or onEmpty then
            error(onEmpty and onEmpty() or "Array contains no element.", 2)
        end
        return
    elseif #self > 1 then
        if allowMultiple == false or onMultiple then
            error(onMultiple and onMultiple(#self) or "Array contains more than one element (" ..
                #self .. ").", 1)
        end
    end
    return self[1]
end

function Array:Bottom(allowEmpty, allowMultiple, onEmpty, onMultiple)
    if #self == 0 then
        if allowEmpty == false or onEmpty then
            error(onEmpty and onEmpty() or "Array contains no element.", 1)
        end
        return
    elseif #self > 1 then
        if allowMultiple == false or onMultiple then
            error(onMultiple and onMultiple(#self) or "Array contains more than one element (" ..
                #self .. ").", 1)
        end
    end
    return self[#self]
end

function Array:Stringify(delimiter)
    local result = ""
    local actualDelimiter = ""
    self:Select(function(element)
        result = result .. actualDelimiter .. element
        actualDelimiter = delimiter or ""
    end)
    return result
end

function Array:Concat(otherArray)
    if not self:Any() then
        if getmetatable(otherArray) == getmetatable(self) then return otherArray end
        return Array:new(otherArray)
    end
    if not otherArray or #otherArray == 0 then return self end

    local result = Array:new {}
    result:AppendMany(self)
    result:AppendMany(otherArray)
    return result
end

function Array:ConcatMany()
    local result = Array:new {}
    for _, values in ipairs(self) do
        for index = 1, #values do
            local value = values[index]
            result:Append(value)
        end
    end
    return result
end

function Array:Aggregate(combinator)
    local result
    for index = 1, #self do
        local value = self[index]
        result = combinator(result, value, index)
    end
    return result
end

function Array:Take(count)
    if #self <= count then return self end

    local result = Array:new {}
    for index = 1, count do result:Append(self[index]) end
    return result
end

function Array:Skip(count)
    if count <= 0 then return self end
    local result = Array:new {}
    for index = 1 + count, #self do result:Append(self[index]) end
    return result
end

function Array:Remove(index)
    local result = table.remove(self, index)
    self.Length = #self - 1
    return result
end

function Array:AppendMany(values)
    local offset = #self
    self.Length = #self + #values
    for index = 1, #values do self[offset + index] = values[index] end
end

function Array:InsertAt(position, value)
    self.Length = #self + 1
    return table.insert(self, position, value)
end

function Array:ToDictionary(getPair)
    local result = Dictionary:new {}
    for index = 1, #self do
        local value = self[index]
        if getPair then
            local pair = getPair(value, index)
            result[pair.Key] = pair.Value
        else
            result[index] = value
        end
    end
    return result
end

function Array:ToGroup(getPair)
    local result = Dictionary:new {}
    for index = 1, #self do
        local value = self[index]
        if getPair then
            local pair = getPair(value, index)
            local current = result[pair.Key] or Array:new {}
            current:Append(pair.Value)
            result[pair.Key] = current
        else
            local current = result[index] or Array:new {}
            current:Append(value)
            result[index] = current
        end
    end
    return result
end

return Array
