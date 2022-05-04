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
    SelectorColumnCount = 12,
    ProductionTimeUnitInTicks = TimeSpan.FromMinutes(1),
    UpdateCountPerTick = 1,
    MaximumEntriesInRecipeList = 7,
}

return result
