local MetadataScan = require "ingteb.MetadataScan"
if global.Game then return end

MetadataScan:Scan()

for _, player in pairs(game.players) do
    local message = "[img=ingteb] migration to 0.6.0"
    player.print(message)
    log(player.name .. ": " .. message)
end
