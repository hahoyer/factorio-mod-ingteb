local mod_gui = require("mod-gui")

local function ReplaceName(gui, moduleName)
    if not gui then return end
    local gui = gui[moduleName]
    if gui then
        gui.name = "ingteb." .. moduleName
        return true
    end
end

for index, player in pairs(game.players) do
    local p = ReplaceName(player.gui.screen, "Presentator")
    local s = ReplaceName(player.gui.screen, "Selector")
    local sr = ReplaceName(player.gui.screen, "SelectRemindor")
    local r = ReplaceName(mod_gui.get_frame_flow(player), "Remindor")

    local l = not global.Players[index].Localisation
    if l then
        global.Players[index].Localisation = nil
    end

    if l or p or s or sr or r then
        local message = "[img=ingteb] migration to 0.5.0"
        player.print(message)
        log(player.name .. ": " .. message)
    end
end
