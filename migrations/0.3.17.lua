local function modify(data, tag)
    local value = data[tag]
    if value == true then
        data[tag]= "1"
    elseif value == false then
        data[tag]= "off"
    end
end

for index, player in pairs(game.players) do
    local playerData = global.Players[index]
    if playerData then
        playerData.Remindor.Settings = nil
        for _, task in ipairs(playerData.Remindor.List) do
            modify(task.Settings,"AutoResearch")
        end
        modify(playerData.SelectRemindor.Settings,"AutoResearch")
        player.print("[ingteb] migration 0.3.17")
    end
end