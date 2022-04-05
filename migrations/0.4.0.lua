local Remindor = require "ingteb.Remindor"

for index, player in pairs(game.players) do
    local playerData = global.Players[index]
    local showLog
    if playerData and playerData.Remindor and playerData.Remindor.List then
        playerData.Remindor.Tasks = Remindor.SerializeForMigration(playerData.Remindor.List)
        playerData.Remindor.List = nil
        showLog = true
    end
    if showLog then 
        player.print("[img=ingteb] migration to 0.4.0") 
        log(player.name .. ": [img=ingteb] migration to 0.4.0")
    end
end

