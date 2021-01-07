local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Helper = require("ingteb.Helper")
local Gui = require("ingteb.Gui")
local History = require("ingteb.History")
local class = require("core.class")
local core = {EventManager = require("core.EventManager")}
local SelectRemindor = require("ingteb.SelectRemindor")
local Remindor = require("ingteb.Remindor")

-- __DebugAdapter.breakpoint(mesg:LocalisedString)
-----------------------------------------------------------------------

local EventManager = class:new("EventManager", core.EventManager)

function EventManager:OnSelectorForeOrBackClick(event)
    self.Player = event.player_index
    Gui:PresentTargetFromCommonKey(self.Global, self.Global.History.Current)
end

function EventManager:OnPresentatorForeClick(event)
    self.Player = event.player_index
    self.Global.History:Fore()
    Gui:PresentTargetFromCommonKey(self.Global, self.Global.History.Current)
end

function EventManager:OnPresentatorBackClick(event)
    self.Player = event.player_index
    self.Global.History:Back()
    Gui:PresentTargetFromCommonKey(self.Global, self.Global.History.Current)
end

function EventManager:DoNothing(event) self.Player = event.player_index end

function EventManager:OnMainKey(event)
    self.Player = event.player_index
    local target = Gui:OnMainButtonPressed(self.Global)
    if target then self.Global.History:ResetTo(target) end
end

function EventManager:OnMainInventoryChanged() Gui:OnMainInventoryChanged() end

function EventManager:OnStackChanged() Gui:OnStackChanged() end

function EventManager:OnResearchChanged(event) Gui:OnResearchFinished(event.research) end

function EventManager:OnForeClicked(event)
    if Gui.Active.Presentator then
        if self.Global.History.IsForePossible then self:OnPresentatorForeClick(event) end
    else
        if self.Global.History.Current then self:OnSelectorForeOrBackClick(event) end
    end
end

function EventManager:OnBackClicked(event)
    if Gui.Active.Presentator then
        if self.Global.History.IsBackPossible then self:OnPresentatorBackClick(event) end
    else
        if self.Global.History.Current then self:OnSelectorForeOrBackClick(event) end
    end
end

function EventManager:OnClose(event) assert(release) end

if false then
    gui.add_handlers {
        Selector = {
            Goods = {
                on_gui_click = function(event)
                    local player = game.players[event.player_index]
                    local target = Gui:PresentSelected(player, event.element.name)
                    if target then self.Global.History:ResetTo(target) end
                    return true
                end,
            },
        },
    }
end

function EventManager:OnGuiEvent(event)
    self.Player = game.players[event.player_index]
    local message = gui.read_action(event)
    if message then
        if message.gui == "Remindor" then
            if message.action == "Closed" then
                Gui:CloseRemindor(self.Global)
            elseif message.action == "Moved" then
                self.Global.Location.Remindor = event.element.location
            else
                assert(release)
            end
        elseif message.gui == "Remindor.Task" then
            if message.action == "Closed" then
                Remindor:CloseTask(self.Global, event.element.name)
            else
                assert(release)
            end
        elseif message.gui == "Presentator" then
            if message.action == "Closed" then
                Gui:ClosePresentator(self.Global)
            elseif message.action == "Moved" then
                self.Global.Location.Presentator = event.element.location
            else
                assert(release)
            end
        elseif message.gui == "Presentator.SpriteButton" then
            if message.action == "Click" then
                local target = Gui:OnGuiClick(self.Global, event, "Presentator")
                if target then self.Global.History:AdvanceWith(target) end
            else
                assert(release)
            end
        elseif message.gui == "Selector" then
            if message.action == "Closed" then
                Gui:Close(self.Global, message.gui)
            elseif message.action == "Moved" then
                self.Global.Location.Selector = event.element.location
            elseif message.action == "Click" then
                local target = Gui:PresentSelected(self.Global, event.element.name)
                if target then self.Global.History:ResetTo(target) end
                return true
            else
                assert(release)
            end
        elseif message.gui == "SelectRemindor" then
            if message.action == "Closed" then
                SelectRemindor:OnClose(self.Player)
                SelectRemindor.Target = nil
            elseif message.action == "Moved" then
                self.Global.Location.SelectRemindor = event.element.location
            elseif message.action == "Enter" then
                local selection = SelectRemindor:GetSelection()
                SelectRemindor:OnClose(self.Player)
                SelectRemindor.Target = nil
                Gui:AddRemindor(self.Global, selection)
            elseif message.action == "Click" then
                SelectRemindor:OnGuiClick(self.Global, Gui:GetObject(self.Global, event.element.name))
            else
                assert(release)
            end
        else
            assert(release)
        end
    elseif event.element.tags then
    else
        assert(
            release --
            or event.name == defines.events.on_gui_opened --
            or event.name == defines.events.on_gui_selected_tab_changed --
        )
    end
end

gui.hook_events(function(event) return EventManager:OnGuiEvent(event) end)

function EventManager:OnTickInitial()
    for index in pairs(global.Players) do Gui:EnsureMainButton(game.players[index]) end
    self:SetHandler(defines.events.on_tick)
end

function EventManager:OnLoad()
    assert(global.Players)
    for _, player in pairs(global.Players) do
        assert(player.History)
        History:adopt(player.History, true)
        player.History:Log("OnLoad")
    end
end

function EventManager:OnPlayerCreated(event)
    self:OnInitializePlayer(game.players[event.player_index])
end

function EventManager:OnPlayerRemoved(event) self.Global.Players[event.player_index] = nil end

function EventManager:OnInitialisePlayer(player)
    global.Players[player.index] = {
        Index = player.index,
        Links = {Presentator = {}, Remindor = {}},
        Location = {},
        History = History:new(),
    }
    Gui:EnsureMainButton(player)
end

function EventManager:OnInitialise()
    global.Players = {}
    for index, player in pairs(game.players) do
        global.Players[index] = {}
        self:OnInitializePlayer(player)
    end
end

function EventManager:new()
    local instance = core.EventManager:new()
    self:adopt(instance)

    self = instance
    EventManager = self
    self:SetHandler("on_init", self.OnInitialise)
    self:SetHandler("on_load", self.OnLoad)
    self:SetHandler(defines.events.on_player_created, self.OnPlayerCreated)
    self:SetHandler(defines.events.on_player_removed, self.OnPlayerRemoved)
    self:SetHandler(defines.events.on_tick, self.OnTickInitial, "initial")
    self:SetHandler(Constants.Key.Main, self.OnMainKey)

    self:SetHandler(defines.events.on_player_main_inventory_changed, self.OnMainInventoryChanged)
    self:SetHandler(defines.events.on_player_cursor_stack_changed, self.OnStackChanged)
    self:SetHandler(defines.events.on_research_finished, self.OnResearchChanged)
    self:SetHandler(defines.events.on_research_started, self.OnResearchChanged)
    self:SetHandler(Constants.Key.Fore, self.OnForeClicked)
    self:SetHandler(Constants.Key.Back, self.OnBackClicked)

    return self
end

return EventManager

