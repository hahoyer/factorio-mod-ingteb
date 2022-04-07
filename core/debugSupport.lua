indent = ""

function AddIndent()
    local result = indent
    indent = indent .. "    "
    return result
end

if (__DebugAdapter and __DebugAdapter.instrument) then
    function dlog(text) log(indent .. text) end
else
    function dlog(text) end
end

function ConditionalBreak(condition, data) if condition then __DebugAdapter.breakpoint("ConditionalBreak "..(data or "")) end end

if (__DebugAdapter and __DebugAdapter.instrument) then
    dassert = assert
else
    dassert = function(condition, ...) return condition end
end

