local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local UI = require("core.UI")
local class = require("core.class")

local Task = class:new("Task")
local Remindor = class:new("Remindor")

function Remindor:SetTask(player, target)
    if not global.Remindor then global.Remindor = {Dictionary = {}, List = Array:new{}} end
    local r = global.Remindor.Dictionary[target.CommonKey]
    if not r then

        List:Append()
     end

end

function Remindor:new(frame)
    local instance = frame.add {type = "frame", direction = "vertical"}
    local head = instance.add {type = "flow", direction = "horizontal"}
    head.add {type = "label", caption = "ingteb-utility.reminder-task"}
    return instance
end

return Remindor
