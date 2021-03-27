local function modify(data, tag)
    if data then
        local value = data[tag]
        if value == nil or value == true or value == false then return end
        data[tag] = value ~= "off"
        return true
    end
end

for index, player in pairs(game.players) do
    local playerData = global.Players[index]
    if playerData then
        if playerData.Remindor then playerData.Remindor.Settings = nil end
        local showLog = false
        for _, task in ipairs(playerData.Remindor.List) do
            if modify(task.Settings, "AutoCrafting") then showLog = true end
        end
        if playerData.SelectRemindor then
            if modify(playerData.SelectRemindor.Settings, "AutoCrafting")then showLog = true end
        end
        if showLog then player.print("[img=ingteb] migration 0.3.21")end
    end
end
