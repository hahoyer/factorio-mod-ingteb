for index, player in pairs(game.players) do
    local l = global.Players[index].Localisation
    if not l or next(l) then
        global.Players[index].Localisation = {}
        local message = "[img=ingteb] migration to 0.5.1"
        player.print(message)
        log(player.name .. ": " .. message)
    end
end
