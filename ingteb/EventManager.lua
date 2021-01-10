local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Table = require("core.Table")
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

-- __DebugAdapter.breakpoint(mesg:LocalisedString)
-----------------------------------------------------------------------

local Class = class:new(
    "EventManager", core.EventManager, {
        Current = {
            get = function(self)
                if self.Modules.Selector.Current then
                    return self.Modules.Selector
                elseif self.Modules.Presentator.Current then
                    return self.Modules.Presentator
                end
            end,
        },
    }
)
local self

function Class:EnsureRemindor()
    Gui:EnsureRemindor(self.Global)
    Remindor = Gui.Remindor
end

function Class:OnSelectorForeOrBackClick(event)
    self.Player = event.player_index
    Gui:PresentTargetFromCommonKey(self.Global, self.Global.History.Current)
end

function Class:OnPresentatorForeClick(event)
    self.Player = event.player_index
    self.Global.History:Fore()
    Gui:PresentTargetFromCommonKey(self.Global, self.Global.History.Current)
end

function Class:OnPresentatorBackClick(event)
    self.Player = event.player_index
    self.Global.History:Back()
    Gui:PresentTargetFromCommonKey(self.Global, self.Global.History.Current)
end

function Class:OnMainKey(event)
    self.Player = event.player_index
    if self.Current then return self.Current:Close() end
    self.Modules.Database:Ensure()
    local targets = self.Modules.Gui:FindTargets()
    if #targets == 1 then
        self.Modules.Presentator:Open(targets[1])
    else
        self.Modules.Selector:Open(targets)
    end
end

function Class:OnMainInventoryChanged(event)
    self.Player = event.player_index
    --    Gui:OnMainInventoryChanged(self.Global)
end

function Class:OnStackChanged() Gui:OnStackChanged() end

function Class:OnResearchChanged(event) Gui:OnResearchFinished(self.Global, event.research) end

function Class:OnForeClicked(event)
    if Gui.Active.Presentator then
        if self.Global.History.IsForePossible then self:OnPresentatorForeClick(event) end
    else
        if self.Global.History.Current then self:OnSelectorForeOrBackClick(event) end
    end
end

function Class:OnBackClicked(event)
    if Gui.Active.Presentator then
        if self.Global.History.IsBackPossible then self:OnPresentatorBackClick(event) end
    else
        if self.Global.History.Current then self:OnSelectorForeOrBackClick(event) end
    end
end

function Class:OnClose(event) assert(release) end

function Class:OnGuiEvent(event)
    local self = self:adopt{}
    self.Player = game.players[event.player_index]
    local message = gui.read_action(event)
    if message then
        if message.action == "Moved" then
            self.Global.Location[message.gui] = event.element.location
            return
        end
        if message.action == "Closed" then return Gui:Close(self.Global, message.gui) end

        if message.module == "Remindor" then return Remindor:OnGuiEvent(event) end

        if message.gui == "Presentator.SpriteButton" or message.gui == "Remindor.SpriteButton" then
            if message.action == "Click" then
                local target = Gui:OnGuiClick(self.Global, event, "Presentator")
                if target then self.Global.History:AdvanceWith(target) end
            else
                assert(release)
            end
        elseif message.gui == "Selector" then
            if message.action == "Click" then
                if event.button == defines.mouse_button_type.left then
                    local target = Gui:PresentSelected(self.Global, event.element.name)
                    if target then self.Global.History:ResetTo(target) end
                else
                    Gui:RemindSelected(
                        self.Global, event.element.name, Helper.GetLocation(event.element)
                    )
                end
            else
                assert(release)
            end
        elseif message.gui == "SelectRemindor" then
            if message.action == "Enter" then
                local selection = SelectRemindor:GetSelection()
                SelectRemindor:OnClose(self.Global)
                Gui:AddRemindor(self.Global, selection)
            elseif message.action == "Click" then
                SelectRemindor:OnGuiClick(
                    self.Global, Gui:GetObject(self.Global, event.element.name)
                )
            elseif message.action == "CountChanged" then
                SelectRemindor:OnTextChanged(self.Global, event.element.text)
            else
                assert(release)
            end
        elseif message.gui == "ingteb" then
            if message.action == "Click" then
                if event.button == defines.mouse_button_type.left then
                    Gui:OnMainButtonPressed(self.Global)
                elseif event.button == defines.mouse_button_type.right then
                    Gui:ToggleRemindor(self.Global)
                else
                    assert(release)
                end
            else
                assert(release)
            end
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

function Class:OnTickInitial()
    self.Modules.Gui:EnsureMainButtons()
    self:SetHandler(defines.events.on_tick)
end

function Class:OnLoad()
    assert(global.Players)
    for _, player in pairs(global.Players) do
        assert(player.History)
        History:adopt(player.History, true)
        player.History:Log("OnLoad")
    end
end

function Class:EnsureMainButton(player) self.Modules.Gui:EnsureMainButton(player) end

function Class:OnPlayerCreated(event) self:OnInitialisePlayer(game.players[event.player_index]) end

function Class:OnPlayerRemoved(event) self.Global.Players[event.player_index] = nil end

function Class:OnInitialisePlayer(player)
    global.Players[player.index] = {
        Index = player.index,
        Links = {Presentator = {}, Remindor = {}},
        Location = {},
        History = History:new(),
    }
    self:EnsureMainButton(player)
end

function Class:OnInitialise()
    global.Players = {}
    for index, player in pairs(game.players) do
        global.Players[index] = {}
        self:OnInitialisePlayer(player)
    end
end

function Class:new()
    local self = Class:adopt{}
    self.Modules = {
        Selector = Selector:new(self),
        Presentator = Presentator:new(self),
        Gui = Gui:new(self),
        Database = Database:new(self),
    }

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

    gui.hook_events(
        function(event)
            if event.element and event.element.get_mod() ~= script.mod_name then return end
            local message = gui.read_action(event)
            if event.name == defines.events.on_gui_location_changed then
                self.Global.Location[event.element.name] = event.element.location
                return
            elseif message then
                if message.module then
                    return self.Modules[message.module]:OnGuiEvent(event)
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
            return self:OnGuiEvent(event)
        end
    )

    return self
end

Class:new()

