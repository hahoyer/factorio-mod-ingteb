local mod_gui = require("mod-gui")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local class = require("core.class")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Database = require("ingteb.Database")

local Class = class:new(
    "Gui", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
        Database = {get = function(self) return self.Parent.Database end},
    }
)

function Class:new(parent) return self:adopt{Parent = parent} end

function Class:EnsureMainButton()
    local frame = mod_gui.get_button_flow(self.Player)
    if frame.ingteb then return end
    gui.build(
        frame, {
            {
                type = "sprite-button",
                name = "ingteb",
                sprite = "ingteb",
                tooltip = {"ingteb-utility.ingteb-button-description"},
                actions = {on_click = {module = self.class.name, action = "Click"}},
            },
        }
    )
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    if message.action == "Click" then
        if event.button == defines.mouse_button_type.left then
            self.Parent:ToggleFloating(event)
        elseif event.button == defines.mouse_button_type.right then
            self.Parent.Modules.Remindor:Toggle()
        else
            assert(release)
        end
    else
        assert(release)
    end
    assert(true)
end

function Class:FindTargets()
    local player = self.Player
    local global = self.Global

    local cursor = player.cursor_stack
    if cursor and cursor.valid and cursor.valid_for_read then
        return {self.Database:GetItem(cursor.name)}
    end

    local cursor = player.cursor_ghost
    if cursor then return {self.Database:GetItem(cursor.name)} end

    local cursor = player.selected
    if cursor then
        local result = self.Database:GetEntity(cursor.name)
        if result.IsResource then
            return {result}
        else
            return {result.Item}
        end
    end

    local cursor = player.opened
    if cursor then

        local t = player.opened_gui_type
        if t == defines.gui_type.custom then assert(release) end
        if t == defines.gui_type.entity then
            assert(release or cursor.object_name == "LuaEntity")

            local inventories = Dictionary:new(defines.inventory) --
            :Select(
                function(_, name)
                    local inventory = cursor.get_inventory(defines.inventory[name])
                    return inventory and #inventory or 0
                end
            ) --
            :Where(function(count) return count > 0 end)

            local result = Dictionary:new{}

            result["Item." .. cursor.name] = true
            if cursor.fluidbox then
                for index = 1, #cursor.fluidbox do
                    result["Fluid." .. cursor.fluidbox[index].name] = true
                end
            end
            if cursor.type == "container" then
                self:GetInventoryData(cursor.get_inventory(defines.inventory.item_main), result)
            elseif cursor.type == "storage-tank" then
            elseif cursor.type == "assembling-machine" then
                self:GetRecipeData(cursor.get_recipe(), result)
            elseif cursor.type == "lab" then
                self:GetInventoryData(cursor.get_inventory(defines.inventory.lab_input), result)
                self:GetInventoryData(cursor.get_inventory(defines.inventory.lab_modules), result)
                self:GetRecipeData(player.force.current_research, result)
            elseif cursor.type == "mining-drill" then
                result["Entity." .. cursor.mining_target.name] = true
                if cursor.burner and cursor.burner.fuel_categories then
                    for category, _ in pairs(cursor.burner.fuel_categories) do
                        result["FuelCategory." .. category] = true
                    end
                end
                self:GetInventoryData(cursor.get_inventory(defines.inventory.fuel))
                self:GetInventoryData(cursor.get_inventory(defines.inventory.item_main))
                self:GetInventoryData(cursor.get_inventory(defines.inventory.mining_drill_modules))
            else
                __DebugAdapter.breakpoint()
            end

            return result:Select(function(_, key) return self:GetObject(global, key) end)
        end

        __DebugAdapter.breakpoint()
    end

    return {}
end

function Class:GetInventoryData(inventory, result)
    if not inventory then return end
    for index = 1, #inventory do
        local stack = inventory[index]
        if stack.valid_for_read then result["Item." .. stack.prototype.name] = true end
    end
end

function Class:GetRecipeData(recipePrototype, result)
    if not recipePrototype then return end
    local recipe = self.Database:GetRecipe(nil, recipePrototype)
    result["Recipe." .. recipePrototype.name] = true
    local inoutItems = recipe.Input:Concat(recipe.Output) --
    inoutItems:Select(function(stack) result[stack.Goods.CommonKey] = true end)
end

------------------------------------

function Class:EnsureDatabase(global)
    assert(release)
    self.Database = Database:Ensure()
    self.Database.OnResearchRefresh = function(self, technology)
        self:OnResearchRefresh(global, technology.Prototype)
    end
    Remindor:RefreshClasses(self.Active.Remindor, self.Database, global)
end

function Class:OnMainInventoryChanged(global)
    assert(release)
    Presentator:RefreshMainInventoryChanged(Database)
    if self.Active.Remindor then Remindor:RefreshMainInventoryChanged(Database) end
end

function Class:OnStackChanged()
    assert(release)
    Presentator:RefreshStackChanged(Database)
    if self.Active.Remindor then Remindor:RefreshStackChanged(Database) end
end

function Class:PresentSelected(global, name)
    assert(release)
    local target = self:GetObject(global, name)
    if target then
        self:Close(global, "Selector")
        self:PresentTarget(global, target)
        return target.CommonKey
    end
end

---comment
---@param global table Global for player
---@param name string CommonKey
---@param location table GuiLocation
---@return string CommonKey
function Class:RemindSelected(global, name, location)
    assert(release)
    local target = self:GetObject(global, name)
    if target then
        self:Close(global, "Selector")
        self:SelectRemindor(global, {ReminderTask = target, Count = 1}, location)
        return target.CommonKey
    end
end

function Class:Close(global, gui)
    assert(release)
    if not self.Active[gui] then return end

    global.Location[gui] = self.Active[gui].location

    if global.IsPopup then return end

    if gui == "Remindor" then
        Remindor:OnClose()
    elseif gui == "Remindor.Settings" then
        self.Player.opened = Remindor.ParentScreen
    elseif gui == "Presentator" then
        Presentator:OnClose(global)
    elseif gui == "Selector" then
        Selector:OnClose(global)
    elseif gui == "SelectRemindor" then
        SelectRemindor:OnClose(global)
    end

    self:Player(gui)[gui].destroy()

    self.Active[gui] = nil
end

function Class:SettingsRemindor(global)
    assert(release)
    if self.Active.RemindorSettings then
        self:Close(global, "RemindorSettings")
    else
        self.Active.RemindorSettings = Remindor:OpenSettings()
    end
end

function Class:RemindorToggleRemoveTask(value)
    assert(release)
    Remindor:ToggleRemoveTask(value)
end

function Class:RemindorToggleAutoResearch(value)
    assert(release)
    Remindor:ToggleAutoResearch(value)
end

function Class:RemindorUpdateAutoCrafting(value)
    assert(release)
    Remindor:UpdateAutoCrafting(value)
end

function Class:SelectTarget(global, targets)
    assert(release)
    Selector:new(global, targets)
    self:ScanActiveGui(game.players[global.Index])
end

function Class:PresentTargetFromCommonKey(global, targetKey)
    local target = self:GetObject(global, targetKey)
    self:PresentTarget(global, target)
end

---@param global table Global data for player
---@param reminderTask table Common
---@param location table GuiLocation (optional)
function Class:SelectRemindor(global, reminderTask, location)
    assert(release)
    SelectRemindor:new(global, reminderTask, location)
end

function Class:EnsureRemindor(global)
    assert(release)
    if self.Remindor then return end
    self.Remindor = Remindor:new(global)
    Remindor = self.Remindor
end

function Class:ToggleRemindor(global)
    assert(release)
    self:EnsureRemindor(global)
    if self.Active.Remindor then
        self:Close(global, "Remindor")
    else
        self.Remindor:Open()
    end
end

function Class:GetObject(global, commonKey)
    assert(release)
    self:EnsureDatabase(global)
    return self.Database:GetProxyFromCommonKey(commonKey)
end

function Class:OnGuiClick(global, event, site)
    assert(release)
    local player = game.players[global.Index]

    local element = event.element
    if element == Class.Active.ingteb then
        return self:OnMainButtonPressed(global)
    elseif element == Class.Active.Selector then
        return
    elseif element == Class.Active.Presentator then
        return
    elseif element == Class.Active.Remindor then
        return
    end

    local target = self:GetObject(global, event.element.name)
    if target and target.Prototype then
        local action = target:GetAction(event)
        if not action then return end
        if action.Selecting then
            if not action.Entity or not player.pipette_entity(action.Entity.Prototype) then
                player.cursor_ghost = action.Selecting.Prototype
            end
        end

        if action.HandCrafting then player.begin_crafting(action.HandCrafting) end

        if action.Research then
            if action.Multiple then
                local message = action.Research:BeginMulipleQueueResearch()
                if message then self:Print(player, message) end
            elseif action.Research.IsReady then
                action.Research:BeginDirectQueueResearch()
            end
        end

        if action.ReminderTask then
            self:SelectRemindor(global, action, Helper.GetLocation(event.element))
        end

        if action.Presenting then
            local result = self:PresentTarget(global, action.Presenting)
            return result
        end

        return
    end

    if site == "Remindor" then
        assert(release)
        -- return Remindor:OnGuiClick(event, self.Active.Remindor, self.Database)
    end

    if true then return end
    local target = global.Links.Presentator[self.Active.Presentator.index]
    if target then
        self:UpdateTabOrder(target.TabOrder, event.element.name)
        return self:PresentTarget(player, target)
    end
end

function Class:UpdateTabOrder(tabOrder, dropIndex)
    assert(release)
    local dropTabIndex = tabOrder[tonumber(dropIndex)]
    tabOrder:Remove(dropIndex)
    tabOrder:Append(dropTabIndex)
end

function Class:OnResearchRefresh(global, research)
    assert(release)
    if Database.IsInitialized then
        self:EnsureDatabase(global)
        Class.Database:RefreshTechnology(research)
        Presentator:RefreshResearchChanged(Database)
        if self.Active.Remindor then Remindor:RefreshResearchChanged() end
    end
end

function Class:OnResearchFinished(global, research)
    assert(release)
    self:OnResearchRefresh(global, research)
end

function Class:Print(player, text)
    assert(release)
    Database:Print(player, text)
end

return Class
