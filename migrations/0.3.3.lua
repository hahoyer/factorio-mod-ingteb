local mod_gui = require("mod-gui")

local oldGlobal = global
oldGlobal.Index = 1
global = {Players = {}}
global.Players[1] = oldGlobal

for _, player in pairs(game.players) do
    if player.gui.top.ingteb then player.gui.top.ingteb.destroy() end
    local frame = mod_gui.get_button_flow(player)
    if frame.ingteb then frame.ingteb.destroy() end
end

game.print("[ingteb] migration 0.3.3")
