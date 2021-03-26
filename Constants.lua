local TimeSpan = require "core.TimeSpan"

local modName = "ingteb"
local result = {
    Key = {
        Main = modName .. "-main-key",
        Back = modName .. "-back-key",
        Fore = modName .. "-fore-key",
    },
    ModName = modName,
    GlobalPrefix = modName .. "_" .. "GlobalPrefix",
    GraphicsPath = "__" .. modName .. "__/graphics/",
    RefreshDelay = 10,
    SelectorColumnCount = 12,
    ProductionTimeUnitInTicks = TimeSpan.FromMinutes(1)
}

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

function ConditionalBreak(condition) if condition then __DebugAdapter.breakpoint("ConditionalBreak", 2) end end

if (__DebugAdapter and __DebugAdapter.instrument) then
    dassert = assert
else
    dassert = function(condition, ...) return condition end
end

return result
