local Array = require "core.Array"
local Dictionary = require "core.Dictionary"

local Table = {}

function Table.new(self, target)
    if getmetatable(target) == Array or getmetatable(target) == Dictionary then
        return target
    elseif #target == 0 and next(target) then
        return Dictionary:new(target)
    elseif not next(target, #target > 0 and #target or nil) then
        return Array:new(target)
    end
    error("Cannot decide if it is an array or a dictionary")
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
    local a = Array:new { "1", "2", "3" }
    dassert(#a == 3)

    local a = Array:new { nil, "2", "3" }
    dassert(#a == 3)

    local a = Array:new { nil, "2", "3", nil, "5" }
    dassert(#a == 5)

    local a = Array:new { nil, "2", "3", nil, "5" }
    a[3] = nil
    dassert(#a == 5)

    local a = Array:new { nil, "2", "3", nil, "5" }
    a:Remove(1)
    dassert(#a == 4)
    dassert(a[1] == "2")

    local a = Array:new { nil, "2", "3", nil, "5" }
    a:Append(nil)
    dassert(#a == 6)

    local a = Array:new { nil, "2", "3", nil, "5" }
    a:InsertAt(3, nil)
    dassert(#a == 6)

    local a = Array:new { nil, "2", "3", nil, "5" }
    a:InsertAt(1, nil)
    dassert(#a == 6)
    dassert(a[6] == "5")

    local a = Array:new { nil, "2", "3", nil, "5" }
    a:Append(nil)
    dassert(#a == 6)
    dassert(a[6] == nil)

    local a = Array:new { "1", "2", "3", "4", "5", "6" }
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
