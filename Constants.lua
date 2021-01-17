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
    AutoCraftingVariants = {"off", "1", "5", "all"},
}

indent = ""

function AddIndent()
    local result = indent
    indent = indent .. "    "
    return result
end

function ConditionalBreak(condition) if condition then __DebugAdapter.breakpoint(2) end end

if not (__DebugAdapter and __DebugAdapter.instrument) then function assert(condition) end end

return result
