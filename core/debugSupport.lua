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

local function ilog(text) --
    log((global.System and global.System.Indent or "") .. text)
end

function ExecuteWithLog(targetFunction, tag, formatResult)
    if not tag or type(tag) ~= "string" then tag = "" end
    ilog(">>>" .. tag)
    local indent = AddIndent()
    local result = targetFunction()
    ResetIndent(indent)
    local resultTag = formatResult and " " .. formatResult(result) or ""
    ilog("<<<" .. tag .. resultTag)
    return result
end

if (__DebugAdapter and __DebugAdapter.instrument) then
    function dlog(text) ilog(text) end
else
    function dlog(text) end
end

function ConditionalBreak(condition, data)
    if condition then
        __DebugAdapter.breakpoint("ConditionalBreak " .. (data or ""))
    end
end

if (__DebugAdapter and __DebugAdapter.instrument) then
    dassert = assert
else
    dassert = function(condition, ...) return condition end
end

function EnsureDebugSupport() EnsureIndent() end
