local function modify(data, tag)
    if data then
        local value = data[tag]
        if value == true then
            data[tag] = "1"
        elseif value == false then
            data[tag] = "off"
        end
    end
end

for index, player in pairs(game.players) do
    local playerData = global.Players and global.Players[index]
    if playerData then
        if playerData.Remindor then playerData.Remindor.Settings = nil end
        for _, task in ipairs(playerData.Remindor.List) do
            modify(task.Settings, "AutoResearch")
        end
        if playerData.SelectRemindor then
            modify(playerData.SelectRemindor.Settings, "AutoResearch")
        end
        player.print("[ingteb] migration 0.3.17")
    end
end
