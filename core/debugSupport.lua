indent = ""

function AddIndent()
    local result = indent
    indent = indent .. "    "
    return result
end

function BackIndent()
    local result = indent
    indent = indent:sub(1,indent:len()-4)
    return result
end

function ilog(text) log(indent .. text) end

if (__DebugAdapter and __DebugAdapter.instrument) then
    function dlog(text) ilog(text) end
else
    function dlog(text) end
end

function ConditionalBreak(condition, data) if condition then __DebugAdapter.breakpoint("ConditionalBreak "..(data or "")) end end

if (__DebugAdapter and __DebugAdapter.instrument) then
    dassert = assert
else
    dassert = function(condition, ...) return condition end
end

