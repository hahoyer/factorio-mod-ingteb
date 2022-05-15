local Array = {}

function Array:__len() return self.Length end

function Array:Append(value)
    self.Length = #self + 1
    self[#self] = value
    return value
end

function Array:Clone(predicate)
    local result = Array:new {}
    for index = 1, #self do
        local value = self[index]
        if not predicate or predicate(value, index) then result:Append(value) end
    end
    return result
end

function Array:EnsureLength()
    local index = next(self)
    local result = 0
    while index do
        if type(index) == "number" and index > result then result = index end
        index = next(self, index)
    end
    self.Length = result
end

function Array:new(target)
    if getmetatable(target) == self then return target end
    if not target then target = {} end
    self.object_name = "Array"
    if getmetatable(target) == "private" then target = Array.Clone(target) end
    setmetatable(target, self)
    self.__index = self
    target:EnsureLength()
    return target
end

------------------------------------------------------

local Dictionary = {}

function Dictionary:Clone(predicate)
    local result = Dictionary:new {}
    for key, value in pairs(self) do
        if not predicate or predicate(value, key) then result[key] = value end
    end
    return result
end

function Dictionary:new(target)
    if getmetatable(target) == self then return target end
    if not target then target = {} end
    self.object_name = "Dictionary"
    if getmetatable(target) == "private" then target = Dictionary.Clone(target) end
    setmetatable(target, self)
    self.__index = self
    return target
end

---------------------------------------------------

return { Array = Array, Dictionary = Dictionary }
