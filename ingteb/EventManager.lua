local events = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local translation = require("__flib__.translation")
local Constants = require("Constants")
local Table = require("core.Table")
local RemindorTask = require "ingteb.remindortask"
local Array = Table.Array
local Dictionary = Table.Dictionary
local Helper = require("ingteb.Helper")
local History = require("ingteb.History")
local class = require("core.class")
local core = {EventManager = require("core.EventManager")}
local Gui = require("ingteb.Gui")
local Selector = require("ingteb.Selector")
local Presentator = require("ingteb.Presentator")
local Database = require("ingteb.Database")
local Spritor = require("ingteb.Spritor")
local Remindor = require("ingteb.Remindor")
local SelectRemindor = require("ingteb.SelectRemindor")

-- __DebugAdapter.breakpoint(mesg:LocalisedString)
-----------------------------------------------------------------------

local Class = class:new(
    "EventManager", core.EventManager, {
        CurrentFloating = {
            get = function(self)
                if self.Modules.Selector.Current then
                    return self.Modules.Selector
                elseif self.Modules.Presentator.Current then
                    return self.Modules.Presentator
                end
            end,
        },
        Database = {
            get = function(self)
                local result = self.Modules.Database
                result:Ensure()
                return result
            end,
        },
    }
)

local self

function Class:SelectRemindorByCommonKey(commonKey, location)
    local remindorTask = {RemindorTask = self.Database:GetProxyFromCommonKey(commonKey)}
    self.Modules.SelectRemindor:Open(remindorTask, location)
end

function Class:SelectRemindor(remindorTask, location)
    self.Modules.SelectRemindor:Open(remindorTask, location)
end

function Class:PresentCurrentTargetFromHistory()
    local target = self.Database:GetProxyFromCommonKey(self.Global.History.Current)
    self.Modules.Presentator:Open(target)
end

function Class:OnSelectorForeOrBackClick(event)
    self.Player = event.player_index
    self:PresentCurrentTargetFromHistory()
end

function Class:OnPresentatorForeClick(event)
    self.Player = event.player_index
    self.Global.History:Fore()
    self:PresentCurrentTargetFromHistory()
end

function Class:OnPresentatorBackClick(event)
    self.Player = event.player_index
    self.Global.History:Back()
    self:PresentCurrentTargetFromHistory()
end

function Class:PresentTarget(target)
    if self.CurrentFloating then self.CurrentFloating:Close() end
    self.Modules.Presentator:Open(target)
    self.Global.History:ResetTo(target.CommonKey)
end

function Class:PresentTargetByCommonKey(targetKey)
    local target = self.Database:GetProxyFromCommonKey(targetKey)
    self:PresentTarget(target)
end

function Class:ToggleFloating()
    if self.CurrentFloating then return self.CurrentFloating:Close() end
    local targets = self.Modules.Gui:FindTargets()
    if #targets == 1 then
        self:PresentTarget(targets[1])
    else
        self.Modules.Selector:Open(targets)
    end
end

function Class:AddRemindor(selection) self.Modules.Remindor:AddRemindorTask(selection) end

function Class:OnMainKey(event)
    self.Player = event.player_index
    self:ToggleFloating()
end

function Class:OnMainInventoryChanged(event)
    self.Player = event.player_index
    self.Modules.Presentator:OnMainInventoryChanged(event)
    self.Modules.Remindor:OnMainInventoryChanged(event)
end

function Class:OnStackChanged(event)
    self.Player = event.player_index
    self.Modules.Presentator:OnStackChanged()
    self.Modules.Remindor:OnStackChanged()
end

function Class:OnResearchChanged(event)
    if not self.Modules.Database.IsInitialized then return end
    self.Database:OnResearchChanged(event)
    self.Modules.Presentator:OnResearchChanged(event)
    self.Modules.Remindor:OnResearchChanged(event)

    if true then return end
    if not self.CurrentFloating then return end
    if self.Database.IsMulipleQueueResearch then
        self.Database.IsRefreshResearchChangedRequired = true
    else
        self.CurrentFloating:RefreshResearchChanged()
    end
end

function Class:OnForeClicked(event)
    self.Player = event.player_index
    if self.CurrentFloating and self.CurrentFloating.class == Presentator then
        if self.Global.History.IsForePossible then self:OnPresentatorForeClick(event) end
    else
        if self.Global.History.Current then self:OnSelectorForeOrBackClick(event) end
    end
end

function Class:OnBackClicked(event)
    self.Player = event.player_index
    if self.CurrentFloating and self.CurrentFloating.class == Presentator then
        if self.Global.History.IsBackPossible then self:OnPresentatorBackClick(event) end
    else
        if self.Global.History.Current then self:OnSelectorForeOrBackClick(event) end
    end
end

function Class:OnTranslationBatch(event)
    if not global.__flib or not global.__flib.translation then 
        translation.init() 
    end
    -- if translation.translating_players_count() == 0 then return false end
    translation.iterate_batch(event)
end

function Class:OnTickInitial(event)
    for _, player in pairs(game.players) do
        self.Player = player
        self:EnsureMainButton()
        if event.tick > 0 then self:RestoreFromSave() end
        self.Modules.Selector:EnsureData()
    end
    return false
end

function Class:OnLoad()
    assert(global.Players)
    for _, player in pairs(global.Players) do
        assert(release or player.History)
        History:adopt(player.History, true)
        player.History:Log("OnLoad")
    end
end

function Class:EnsureMainButton() self.Modules.Gui:EnsureMainButton() end

function Class:OnPlayerCreated(event)
    self.Player = event.player_index
    self:OnInitialisePlayer()
end

function Class:OnPlayerJoined(event)
    self.Player = event.player_index
    self:OnInitialisePlayer()
end

function Class:OnPlayerRemoved(event)
    self.Player = event.player_index
    self.Global.Players[event.player_index] = nil

    if translation.is_translating(event.player_index) then translation.cancel(event.player_index) end

end

function Class:OnStringTranslated(event)
    self.Player = event.player_index
    self.Database:OnStringTranslated(event)
end

function Class:OnInitialisePlayer()
    global.Players[self.Player.index] = {
        Index = self.Player.index,
        Links = {Presentator = {}, Remindor = {}},
        Location = {},
        History = History:new(),
        Remindor = {Settings = {}},
    }
    self:EnsureMainButton()
    self.RestoreFromSaveDone = true
end

function Class:OnSettingsChanged(event)
    self.Player = event.player_index
    self:RestoreFromSave()
    self.Modules.Selector:OnSettingsChanged(event)
    self.Modules.Presentator:OnSettingsChanged(event)
    self.Modules.SelectRemindor:OnSettingsChanged(event)
    self.Modules.Remindor:OnSettingsChanged(event)
end

function Class:OnInitialise()
    global.Players = {}
    for index, player in pairs(game.players) do
        self.Player = player
        global.Players[index] = {}
        self:OnInitialisePlayer()
    end
end

function Class:OnConfigurationChanged() translation.init() end

function Class:RestoreFromSave()
    if self.RestoreFromSaveDone then return end
    self.RestoreFromSaveDone = true
    self.Global.Index = self.Player.index
    self.Modules.Selector:RestoreFromSave(self)
    self.Modules.Presentator:RestoreFromSave(self)
    self.Modules.SelectRemindor:RestoreFromSave(self)
    self.Modules.Remindor:RestoreFromSave(self)
end

function Class:new()
    local self = self:adopt{}
    self.Modules = {
        Selector = Selector:new(self),
        Presentator = Presentator:new(self),
        Gui = Gui:new(self),
        Database = Database:new(self),
        Spritor = Spritor:new(self),
        Remindor = Remindor:new(self),
        SelectRemindor = SelectRemindor:new(self),
    }

    self:SetHandler("on_init", self.OnInitialise)
    self:SetHandler("on_load", self.OnLoad)
    self:SetHandler("on_configuration_changed", self.OnConfigurationChanged)
    self:SetHandler(defines.events.on_player_created, self.OnPlayerCreated)
    --    self:SetHandler(defines.events.on_player_joined_game, self.OnPlayerJoined)
    self:SetHandler(defines.events.on_tick, self.OnTickInitial, "OnTickInitial")
    self:SetHandler(defines.events.on_tick, self.OnTranslationBatch, "OnTranslationBatch")
    self:SetHandler(Constants.Key.Main, self.OnMainKey)

    self:SetHandler(defines.events.on_player_main_inventory_changed, self.OnMainInventoryChanged)
    self:SetHandler(defines.events.on_player_cursor_stack_changed, self.OnStackChanged)
    self:SetHandler(defines.events.on_research_finished, self.OnResearchChanged)
    self:SetHandler(defines.events.on_research_started, self.OnResearchChanged)
    self:SetHandler(defines.events.on_runtime_mod_setting_changed, self.OnSettingsChanged)
    self:SetHandler(Constants.Key.Fore, self.OnForeClicked)
    self:SetHandler(Constants.Key.Back, self.OnBackClicked)
    self:SetHandler(defines.events.on_string_translated, self.OnStringTranslated)
    gui.hook_events(
        function(event)
            self.Player = event.player_index
            if event.element and event.element.get_mod() ~= script.mod_name then return end
            local message = gui.read_action(event)
            if event.name == defines.events.on_gui_location_changed then
                self.Global.Location[event.element.name] = event.element.location
            elseif message then
                if message.module then
                    self.Modules[message.module]:OnGuiEvent(event)
                else
                    assert(release)
                end
            elseif event.element and event.element.tags then
            else
                assert(
                    release --
                    or event.name == defines.events.on_gui_opened --
                    or event.name == defines.events.on_gui_selected_tab_changed --
                    or event.name == defines.events.on_gui_closed --
                )
            end
        end
    )

    return self
end

Class:new()

function Class:OnGuiEvent(event)
    assert(release)
    self.Player = game.players[event.player_index]
    local message = gui.read_action(event)
    if message then
        if message.gui == "SelectRemindor" then
            if message.action == "Click" then
                SelectRemindor:OnGuiClick(
                    self.Global, Gui:GetObject(self.Global, event.element.name)
                )
            else
                assert(release)
            end
        else
            assert(release)
        end
    end
end

