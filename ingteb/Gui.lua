local mod_gui = require("mod-gui")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local UI = require("core.UI")
local Presentator = require("ingteb.Presentator")
local Selector = require("ingteb.Selector")
local Remindor = require("ingteb.Remindor")
local SelectRemindor = require("ingteb.SelectRemindor")
local Database = require("ingteb.Database")
local Entity = require("ingteb.Entity")

local Gui = {Active = {}}

function Gui:EnsureDatabase()
    self.Database = Database:Ensure()
    Remindor:RefreshClasses(self.Active.Remindor, self.Database)
end

function Gui:GetRecipeData(recipePrototype, result)
    if recipePrototype then
        local recipe = self.Database:GetRecipe(nil, recipePrototype)
        result["Recipe." .. recipePrototype.name] = true
        local inoutItems = recipe.Input:Concat(recipe.Output) --
        inoutItems:Select(function(stack) result[stack.Goods.CommonKey] = true end)
    end
end

function Gui:GetInventoryData(inventory, result)
    if inventory then
        for index = 1, #inventory do
            local stack = inventory[index]
            if stack.valid_for_read then result["Item." .. stack.prototype.name] = true end
        end
    end
end

function Gui:OnMainInventoryChanged()
    Presentator:RefreshMainInventoryChanged(Database)
    if self.Active.Remindor then Remindor:RefreshMainInventoryChanged(Database) end
end

function Gui:OnStackChanged()
    Presentator:RefreshStackChanged(Database)
    if self.Active.Remindor then Remindor:RefreshStackChanged(Database) end
end

function Gui:PresentSelected(global, name)
    local target = self:GetObject(name)
    if target then
        Gui:Close(global, "Selector")
        Gui:PresentTarget(global, target)
        return target.CommonKey
    end
end

function Gui:FindTargets(global)
    local player = game.players[global.Index]
    self:EnsureDatabase()
    assert(release or self.Active.ingteb)
    assert(release or not self.Active.Selector)
    assert(release or not self.Active.Presentator)

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
                Gui:GetInventoryData(cursor.get_inventory(defines.inventory.item_main), result)
            elseif cursor.type == "storage-tank" then
            elseif cursor.type == "assembling-machine" then
                Gui:GetRecipeData(cursor.get_recipe(), result)
            elseif cursor.type == "lab" then
                Gui:GetInventoryData(cursor.get_inventory(defines.inventory.lab_input), result)
                Gui:GetInventoryData(cursor.get_inventory(defines.inventory.lab_modules), result)
                Gui:GetRecipeData(player.force.current_research, result)
            elseif cursor.type == "mining-drill" then
                result["Entity." .. cursor.mining_target.name] = true
                if cursor.burner and cursor.burner.fuel_categories then
                    for category, _ in pairs(cursor.burner.fuel_categories) do
                        result["FuelCategory." .. category] = true
                    end
                end
                Gui:GetInventoryData(cursor.get_inventory(defines.inventory.fuel))
                Gui:GetInventoryData(cursor.get_inventory(defines.inventory.item_main))
                Gui:GetInventoryData(cursor.get_inventory(defines.inventory.mining_drill_modules))
            else
                __DebugAdapter.breakpoint()
            end

            return result:Select(function(_, key) return self:GetObject(key) end)
        end

        __DebugAdapter.breakpoint()
    end

    return {}
end

function Gui:ScanActiveGui(player)
    self.Active.ingteb = mod_gui.get_button_flow(player).ingteb
    self.Active.Selector = player.gui.screen.Selector
    self.Active.Presentator = player.gui.screen.Presentator
    self.Active.Remindor = mod_gui.get_frame_flow(player).Remindor

end

function Gui:Close(global, gui)
    local player = game.players[global.Index]
    global.Location[gui]= self.Active[gui].location 
    player.gui.screen[gui].destroy()
    self.Active[gui] = nil
end

function Gui:ClosePresentator(global)
    local player = game.players[global.Index]
    if player.gui.screen.SelectRemindor then return end
    if not self.Active.Presentator then return end
    self:Close(global, "Presentator")
    Presentator:OnClose()
    global.Links.Presentator = {}
end

function Gui:SelectTarget(player, targets)
    Selector:new(player, targets)
    self:ScanActiveGui(player)
end

function Gui:PresentTargetFromCommonKey(global, targetKey)
    local target = self:GetObject(targetKey)
    self:PresentTarget(global, target)
end

function Gui:PresentTarget(global, target)
    local player = game.players[global.Index]
    local actualTarget = target
    if target.class == Entity and target.Item then actualTarget = target.Item end

    assert(release or actualTarget.Prototype)

    self:ClosePresentator(global)
    Presentator:new(global, actualTarget)
    self:ScanActiveGui(player)
    return target.CommonKey
end

function Gui:SelectRemindor(player, target) SelectRemindor:new(player, target) end

function Gui:AddRemindor(player, selection)
    if not self.Active.Remindor then
        local frame = mod_gui.get_frame_flow(player).add {
            type = "frame",
            name = "Remindor",
            direction = "vertical",
        }
        self.Active.Remindor = frame
        Remindor:new(frame)
    end
    Remindor:SetTask(selection)
end

function Gui:OnMainButtonPressed(global)
    assert(release or self.Active.ingteb)
    assert(release or not self.Active.Selector or not self.Active.Presentator)

    if self.Active.Selector then
        self:Close(global, "Selector")
    elseif self.Active.Presentator then
        self:ClosePresentator(global)
    else
        local targets = self:FindTargets(global)
        game.players[global.Index].opened = nil
        if #targets == 1 then
            return self:PresentTarget(global, targets[1])
        else
            self:SelectTarget(global, targets)
        end
    end
end

function Gui:EnsureMainButton(player)
    if player then
        if player.gui.top.ingteb then player.gui.top.ingteb.destroy() end
        if mod_gui.get_button_flow(player).ingteb == nil then
            assert(release or not self.Active.ingteb)
            mod_gui.get_button_flow(player).add {
                type = "sprite-button",
                name = "ingteb",
                sprite = "ingteb",
                tooltip = {"ingteb-utility.ingteb-button-description"},
            }
        end
        self:ScanActiveGui(player)
    else
        for _, player in pairs(game.players) do self:EnsureMainButton(player) end
    end
end

function Gui:GetObject(commonKey)
    self:EnsureDatabase()
    return self.Database:GetProxyFromCommonKey(commonKey)
end

function Gui:OnGuiClick(global, event, site)
    local player = game.players[global.Index]

    local element = event.element
    if element == Gui.Active.ingteb then
        return self:OnMainButtonPressed(global)
    elseif element == Gui.Active.Selector then
        return
    elseif element == Gui.Active.Presentator then
        return
    elseif element == Gui.Active.Remindor then
        return
    end

    local target = self:GetObject(event.element.name)
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
            if action.Research.IsReady then
                self:DirectQueueResearch(global, action.Research)
            elseif action.Multiple then
                self:MulipleQueueResearch(global, action.Research)
            end
        end

        if action.ReminderTask then self:SelectRemindor(global, action.ReminderTask) end

        if action.Presenting then
            local result = self:PresentTarget(global, action.Presenting)
            return result
        end

        return
    end

    if site == "Remindor" then
        return Remindor:OnGuiClick(event, self.Active.Remindor, self.Database)
    end

    if true then return end
    local target = global.Links.Presentator[self.Active.Presentator.index]
    if target then
        self:UpdateTabOrder(target.TabOrder, event.element.name)
        return self:PresentTarget(player, target)
    end
end

function Gui:UpdateTabOrder(tabOrder, dropIndex)
    local dropTabIndex = tabOrder[tonumber(dropIndex)]
    tabOrder:Remove(dropIndex)
    tabOrder:Append(dropTabIndex)
end

function Gui:OnResearchRefresh(research)
    if Database.IsInitialized then
        Gui:EnsureDatabase()
        Gui.Database:RefreshTechnology(research)
        Presentator:RefreshResearchChanged(Database)
        if self.Active.Remindor then Remindor:RefreshResearchChanged() end
    end
end

function Gui:OnResearchFinished(research) Gui:OnResearchRefresh(research) end
function Gui:Print(player, text) player.print {"", "[ingteb]", text} end

function Gui:DirectQueueResearch(player, research)
    local added = player.force.add_research(research.Name)
    if added then
        self:Print(
            player, {"ingteb-utility.added-to-research-queue", research.Prototype.localised_name}
        )
        Gui:OnResearchRefresh(research.Prototype)
    else
        self:Print(
            player,
                {"ingteb-utility.not-added-to-research-queue", research.Prototype.localised_name}
        )
    end
end

function Gui:MulipleQueueResearch(player, research)
    local queued = Array:new{}
    local message = "ingteb-utility.research-no-ready-prerequisite"
    repeat
        local ready = research.TopReadyPrerequisite
        if ready then message = "ingteb-utility.not-added-to-research-queue" end
        local added = ready and player.force.add_research(ready.Name)
        if added then queued:Append(ready) end

    until not added

    queued:Select(
        function(research)
            self:Print(
                player,
                    {"ingteb-utility.added-to-research-queue", research.Prototype.localised_name}
            )
            Gui:OnResearchRefresh(research.Prototype)
        end
    )
    if not queued:Any() then self:Print(player, {message, research.Prototype.localised_name}) end

end

return Gui
