local mod_gui = require("mod-gui")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Table = require("core.Table")
local class = require("core.class")
local Array = Table.Array
local Dictionary = Table.Dictionary

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
            dassert()
        end
    else
        dassert()
    end
    dassert(true)
end

function Class:FindTargets(selected)
    local player = self.Player

    if selected then
        local result = self.Database:GetFromSelection(selected)
        if result then
            if result.class.name ~= "Entity" or result.IsResource then
                return {result}
            else
                return {result.Item}
            end
        end
    end

    local cursor = player.opened
    if cursor then
        dassert(not selected)

        local t = player.opened_gui_type
        if t == defines.gui_type.custom then return end
        if t == defines.gui_type.entity then
            dassert(cursor.object_name == "LuaEntity")

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
                dassert()
            end

            return result:ToArray(
                function(_, key) return self.Database:GetProxyFromCommonKey(key) end
            )
        end
        local message --
        = "not implemented: defines.gui_type." .. Dictionary: --
        new(defines.gui_type): --
        Where(function(value) return value == t end): --
        ToArray(function(_, key) return key end).Top()

        log(message)
        dassert()
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

function Class:PresentTargetFromCommonKey(global, targetKey)
    local target = self:GetObject(global, targetKey)
    self:PresentTarget(global, target)
end

return Class
