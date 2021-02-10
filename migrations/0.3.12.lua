for index,player in pairs(game.players) do
    local playerData = global.Players[index]
    if playerData then
        if not playerData.Remindor.List then playerData.Remindor.List = {} end
        if not playerData.Remindor.Links then playerData.Remindor.Links = {} end
        player.print("[ingteb] migration 0.3.12")
    end
end

