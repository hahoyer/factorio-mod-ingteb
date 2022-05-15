local mod_gui = require("mod-gui")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")

local class = require("core.class")
local Array = require "core.Array"
local Dictionary = require "core.Dictionary"

local Class = class:new(
    "Gui", nil, {
    Player = { get = function(self) return self.Parent.Player end },
    PlayerGlobal = { get = function(self) return self.Parent.PlayerGlobal end },
    Database = { get = function(self) return self.Parent.Database end },
}
)

function Class:new(parent) return self:adopt { Parent = parent } end

function Class:EnsureMainButton()
    local frame = mod_gui.get_button_flow(self.Player)
    if frame.ingteb then return end
    gui.build(
        frame, {
        {
            type = "sprite-button",
            name = "ingteb",
            sprite = "ingteb",
            tooltip = { "ingteb-utility.ingteb-button-description" },
            actions = { on_click = { module = self.class.name, action = "Click" } },
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

function Class:FindOpenedTargets()
    local player = self.Player

    local cursor = player.opened
    if cursor then
        local t = player.opened_gui_type
        if t == defines.gui_type.custom then return end
        if t == defines.gui_type.entity then
            dassert(cursor.object_name == "LuaEntity")
            local prototype = cursor.prototype
            local entity = self.Database:GetEntity(nil, prototype)

            local result = Dictionary:new {}

            if prototype.mineable_properties then
                for index = 1, #prototype.mineable_properties.products do
                    result["Item." .. prototype.mineable_properties.products[index].name] = true
                end
            end

            if cursor.fluidbox then
                for index = 1, #cursor.fluidbox do
                    if cursor.fluidbox[index] then
                        result["Fluid." .. cursor.fluidbox[index].name] = true
                    end
                end
            end

            if cursor.type == "lab" and player.force.current_research then
                self:GetTechnologyData(player.force.current_research.prototype, result)
            end

            if cursor.type == "mining-drill" then
                result["Entity." .. cursor.mining_target.name] = true
            end

            if cursor.type == "rocket-silo" or --
                cursor.type == "assembling-machine" or --
                cursor.type == "furnace" --
            then self:GetRecipeData(cursor.get_recipe(), result) end

            for index = 1, Dictionary:new(defines.inventory):Count() do
                self:GetInventoryData(cursor.get_inventory(index), result)
            end

            if cursor.burner and cursor.burner.fuel_categories then
                self:GetInventoryData(cursor.get_inventory(defines.inventory.fuel), result)
                for category, _ in pairs(cursor.burner.fuel_categories) do
                    result["FuelCategory." .. category] = true
                end
            end

            return result:ToArray(
                function(_, key) return self.Database:GetProxyFromCommonKey(key) end
            )
        end
        local message--
        = "not implemented: defines.gui_type." .. Dictionary:--
            new(defines.gui_type):--
            Where(function(value) return value == t end):--
            ToArray(function(_, key) return key end).Top()

        log(message)
        dassert()
    end
end

function Class:FindTargets(selected)
    local player = self.Player
    local result = self:FindOpenedTargets()
    if result then return result end

    if selected then
        local result = self.Database:GetFromSelection(selected)
        if result then
            if result.class.name ~= "Entity" then
                return { result }
            else
                return { result.Item }
            end
        end
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
end

function Class:GetTechnologyData(target, result)
    if not target then return end
    local technology = self.Database:GetTechnology(nil, target)
    result["Technology." .. target.name] = true
end

function Class:PresentTargetFromCommonKey(global, targetKey)
    local target = self:GetObject(global, targetKey)
    self:PresentTarget(global, target)
end

return Class
