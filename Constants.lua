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
}

release = not (__DebugAdapter and __DebugAdapter.instrument)
indent = ""

function AddIndent()
    local result = indent
    indent = indent .. "    "
    return result
end

return result
