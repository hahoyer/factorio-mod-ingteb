local function EnsureIndent()
    if not global.System then global.System = {} end
    if not global.System.Indent then global.System.Indent = "" end
end

function AddIndent()
    EnsureIndent()
    local result = global.System.Indent
    global.System.Indent = result .. "    "
    return result
end

function ResetIndent(value)
    EnsureIndent()
    global.System.Indent = value
end

function ilog(text)
    EnsureIndent()
    log(global.System.Indent .. text)
end

if (__DebugAdapter and __DebugAdapter.instrument) then
    function dlog(text) ilog(text) end
else
    function dlog(text) end
end

function ConditionalBreak(condition, data)
    if condition then __DebugAdapter.breakpoint("ConditionalBreak " .. (data or "")) end
end

if (__DebugAdapter and __DebugAdapter.instrument) then
    dassert = assert
else
    dassert = function(condition, ...) return condition end
end

