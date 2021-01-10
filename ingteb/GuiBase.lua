local mod_gui = require("mod-gui")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local UI = require("core.UI")

local GuiBase = {Active = {}}

function GuiBase:OnOpen(gui) 
    if self.Active[gui] then return end
    self.Active[gui] = self:PlayerGui(gui)[gui]
end

function GuiBase:PlayerGui(gui)
    if gui == "Remindor" then
        return mod_gui.get_frame_flow(self.Player)
    elseif gui == "ingteb" then
        return mod_gui.get_button_flow(self.Player)
    else
        return self.Player.gui.screen
    end
end

function GuiBase:OnClose(global, gui)
    if not self.Active[gui] then return false end
    global.Location[gui] = self.Active[gui].location
    if global.IsPopup then return end
    self:Player(gui)[gui].destroy()
    self.Active[gui] = nil
end

return GuiBase
