require("ingteb.EventManager")
if true then return end

local b = {}

function b.Fu() 
    local x = 1
    return 
end

local a = {}

setmetatable(a, {__index = b})

a.Fu()
a.Fu()
local x = 1
