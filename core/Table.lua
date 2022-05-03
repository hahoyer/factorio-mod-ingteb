local Dictionary = {}
local Array = {}

function Dictionary:Clone(predicate)
    local result = Dictionary:new{}
    for key, value in pairs(self) do
        if not predicate or predicate(value, key) then result[key] = value end
    end
    return result
end

function Array:Clone(predicate)
    local result = Array:new{}
    for index = 1, #self do
        local value = self[index]
        if not predicate or predicate(value, index) then result:Append(value) end
    end
    return result
end

function Dictionary:Where(predicate) return self:Clone(predicate) end

function Array:Where(predicate) return self:Clone(predicate) end

function Array:Sort(order) table.sort(self, order) end

function Array:Intersection(other)
    return other:Where(function(entry) return self:Contains(entry) end)
end

function Array:Union(other)
    return self:Concat(other:Where(function(entry) return not self:Contains(entry) end))
end

function Array:Except(other) return self:Where(function(entry) return not other:Contains(entry) end) end

function Dictionary:Except(other) return self:Where(function(_, key) return not other[key] end) end

function Array:IntersectMany()
    if not self:Any() then return Array:new{} end
    local result = self[1]
    for index = 2, #self do result = result:Intersection(self[index]) end
    return result
end

function Array:UnionMany()
    if not self:Any() then return Array:new{} end
    local result = self[1]
    for index = 2, #self do result = result:Union(self[index]) end
    return result
end

function Dictionary:new(target)
    if not target then target = {} end
    self.object_name = "Dictionary"
    if getmetatable(target) == "private" then target = Dictionary.Clone(target) end
    setmetatable(target, self)
    self.__index = self
    return target
end

function Array:new(target)
    if not target then target = {} end
    self.object_name = "Array"
    if getmetatable(target) == "private" then target = Array.Clone(target) end
    setmetatable(target, self)
    self.__index = self
    target:EnsureLength()
    return target
end

function Array:__len() return self.Length end

function Array:EnsureLength()
    local index = next(self)
    local result = 0
    while index do
        if type(index) == "number" and index > result then result = index end
        index = next(self, index)
    end
    self.Length = result
end

function Array:FromNumber(number)
    local target = Array:new()
    for index = 1, number do target:Append(index) end
    return target
end

function Dictionary:Select(transformation)
    local result = Dictionary:new{}
    for key, value in pairs(self) do result[key] = transformation(value, key) end
    return result
end

function Array:Select(transformation)
    local result = Array:new{}
    for index = 1, #self do
        if self[index] then result:Append(transformation(self[index], index)) end
    end
    return result
end

function Array:Compact()
    local result = Array:new{}
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

function Dictionary:Count(predicate)
    local result = 0
    for key, value in pairs(self) do
        if not predicate or predicate(value, key) then result = result + 1 end
    end
    return result
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

function Dictionary:All(predicate)
    for key, value in pairs(self) do if not predicate(value, key) then return false end end
    return true
end

function Array:All(predicate)
    for index = 1, #self do
        local value = self[index]
        if not predicate(value, index) then return false end
    end
    return true
end

function Dictionary:Any(predicate)
    for key, value in pairs(self) do
        if not predicate or predicate(value, key) then return true end
    end
    return nil
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

function Dictionary:ToDictionary(getPair)
    local result = Dictionary:new{}
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

function Array:GetUniqueEntries(predicate)
    local result = self:ToDictionary(function(value)
        return {Key = predicate(value), Value = value}
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

function Array:ToDictionary(getPair)
    local result = Dictionary:new{}
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
    local result = Dictionary:new{}
    for index = 1, #self do
        local value = self[index]
        if getPair then
            local pair = getPair(value, index)
            local current = result[pair.Key] or Array:new{}
            current:Append(pair.Value)
            result[pair.Key] = current
        else
            local current = result[index] or Array:new{}
            current:Append(value)
            result[index] = current
        end
    end
    return result
end

function Dictionary:ToArray(getItem)
    local result = Array:new{}
    if not getItem then getItem = function(value) return value end end
    for key, value in pairs(self) do result:Append(getItem(value, key)) end
    return result
end

function Array:ToArray(getItem)
    local result = Array:new{}
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

--- Get the first element
---@param allowEmpty boolean optional default: true
---@param allowMultiple boolean optional default: true
---@param onEmpty any error message function, opional
---@param onMultiple any error message function, opional
function Dictionary:Top(allowEmpty, allowMultiple, onEmpty, onMultiple)
    local result
    for key, value in pairs(self) do
        if allowMultiple ~= false then return {Key = key, Value = value} end
        if result then
            error(onMultiple and onMultiple(#self) or "Array contains more than one element (" ..
                      #self .. ").", 1)
        end
        result = {Key = key, Value = value}
    end

    if result then return result end

    if allowEmpty == false or onEmpty then
        error(onEmpty and onEmpty() or "Array contains no element.", 1)
    end
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

    local result = Array:new{}
    result:AppendMany(self)
    result:AppendMany(otherArray)
    return result
end

function Array:ConcatMany()
    local result = Array:new{}
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

function Array:Take(count)
    if #self <= count then return self end

    local result = Array:new{}
    for index = 1, count do result:Append(self[index]) end
    return result
end

function Array:Skip(count)
    if count <= 0 then return self end
    local result = Array:new{}
    for index = 1 + count, #self do result:Append(self[index]) end
    return result
end

function Array:Remove(index)
    local result =  table.remove(self, index)
    self.Length = #self - 1
    return result
end

function Array:Append(value)
    self.Length = #self + 1
    self[#self] = value
    return value
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

local Table = {Array = Array, Dictionary = Dictionary}

function Table.new(self, target)
    if #target == 0 and next(target) then
        return self.Dictionary:new(target)
    elseif not next(target, #target > 0 and #target or nil) then
        return self.Array:new(target)
    end
    error("Cannot decide if it is an array or a dictionary")
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

function Table.AppendForKey(self, key, target)
    if key then
        local list = self[key]
        if not list then
            list = {}
            self[key] = list
        end
        table.insert(list, target)
    end
end

local function UnittestArray()
    local a = Array:new{"1", "2", "3"}
    dassert(#a == 3)

    local a = Array:new{nil, "2", "3"}
    dassert(#a == 3)

    local a = Array:new{nil, "2", "3", nil, "5"}
    dassert(#a == 5)

    local a = Array:new{nil, "2", "3", nil, "5"}
    a[3] = nil
    dassert(#a == 5)

    local a = Array:new{nil, "2", "3", nil, "5"}
    a:Remove(1)
    dassert(#a == 4)
    dassert(a[1] == "2")

    local a = Array:new{nil, "2", "3", nil, "5"}
    a:Append(nil)
    dassert(#a == 6)

    local a = Array:new{nil, "2", "3", nil, "5"}
    a:InsertAt(3, nil)
    dassert(#a == 6)

    local a = Array:new{nil, "2", "3", nil, "5"}
    a:InsertAt(1, nil)
    dassert(#a == 6)
    dassert(a[6] == "5")

    local a = Array:new{nil, "2", "3", nil, "5"}
    a:Append(nil)
    dassert(#a == 6)
    dassert(a[6] == nil)

    local a = Array:new{"1", "2", "3", "4", "5", "6"}
    a:Remove(1)
    dassert(#a == 5)
    dassert(a[5] == "6")
    dassert(a[6] == nil)

    -- dassert(false)
end

local function Unittest()
    UnittestArray()
    return true
end

dassert(Unittest())
return Table
