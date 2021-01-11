local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")

ColumnCount = 12

---@param data table Dictionary Dictionary where the key is searched
---@param key string
---@param value any Value to use if key is not jet contained in data
---@return any the value stored at key
local function EnsureKey(data, key, value)
    local result = data[key]
    if not result then
        result = value or {}
        data[key] = result
    end
    return result
end

local Class = class:new(
    "Selector", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
    }
)

function Class:new(parent) return Class:adopt{Parent = parent} end

function Class:Open(targets)
    local player = self.Player
    local global = self.Global
    local content = self:GetGui(targets)

    local result = Helper.CreateFrameWithContent(
        self.class.name, player.gui.screen, content, {"ingteb-utility.selector"}
    )

    self.Current = result.Main
    player.opened = result.Main

    if global.Location.Selector then
        result.Main.location = global.Location.Selector
    else
        result.Main.force_auto_center()
        global.Location.Selector = result.Main.location
    end
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    if message.action == "Closed" then
        self:Close()
    else
        assert(release)
    end
end

function Class:GetGui(targets)
    if #targets > 0 then
        return self:GetTargetsGui(Array:new{targets})
    else
        return self:GetAllItemsGui()
    end
end

function Class:Close()
    if self.Current then
        self.Current.destroy()
        self.Current = nil
    end
end

function Class:GetTargets(targets)
    return targets:Select(
        function(target)
            if target.SpriteType == "fuel-category" then
                return {
                    type = "sprite-button",
                    sprite = target.Name,
                    name = target.CommonKey,
                    tooltip = target.LocalisedName,
                }
            else
                return {
                    type = "choose-elem-button",
                    elem_type = target.SpriteType,
                    name = target.CommonKey,
                    elem_mods = {elem_value = target.Name, locked = true},
                }
            end
        end
    )

end

function Class:GetTargetsGui(targets)
    return {
        type = "flow",
        direction = "vertical",
        children = {
            {type = "table", column_count = ColumnCount, children = Class:GetTargets(targets)},
            {type = "line", direction = "horizontal"},
            {type = "table", column_count = ColumnCount},
        },

    }

end

local SelectorCache = {}

function SelectorCache.EnsureGroups()
    local self = SelectorCache
    if not self.Groups then
        local maximalColumns = 0
        self.Groups = Dictionary:new{}
        local targets = {game.item_prototypes, game.fluid_prototypes}
        for _, domain in pairs(targets) do
            for _, goods in pairs(domain) do
                local group = EnsureKey(self.Groups, goods.group.name, Dictionary:new{})
                local subgroup = EnsureKey(group, goods.subgroup.name, Array:new{})
                subgroup:Append(goods)
                if maximalColumns < subgroup:Count() then
                    maximalColumns = subgroup:Count()
                end
            end
        end
        self.ColumnCount =
            maximalColumns < ColumnCount and maximalColumns or self.Groups:Count() * 2
    end
    return self.Groups
end

function Class:GetGoodsPanel(goods)
    local name =
        (goods.object_name == "LuaItemPrototype" and "Item" or "Fluid") .. "." .. goods.name
    return {
        type = "sprite-button",
        sprite = (goods.object_name == "LuaItemPrototype" and "item" or "fluid") .. "." .. goods.name,
        name = name,
        tooltip = goods.localised_name,
        actions = {on_click = {gui = "Selector", action = "Click"}},
    }
end

function Class:GetSubGroupPanel(group)
    return group:ToArray():Select(
        function(subgroup)
            return {
                type = "table",
                column_count = SelectorCache.ColumnCount,
                children = subgroup:Select(
                    function(goods) return self:GetGoodsPanel(goods) end
                ),
            }
        end
    )
end

function Class:GetAllItemsGui()
    local groups = SelectorCache:EnsureGroups()

    return {
        type = "tabbed-pane",
        tabs = groups:ToArray():Select(
            function(group)
                local groupHeader = group[next(group)][1].group
                return {
                    tab = {
                        type = "tab",
                        caption = "[item-group=" .. groupHeader.name .. "]",
                        style = "ingteb-big-tab",
                        tooltip = groupHeader.localised_name,
                    },
                    content = {
                        type = "flow",
                        direction = "vertical",
                        children = {
                            {
                                type = "scroll-pane",
                                horizontal_scroll_policy = "never",
                                direction = "vertical",
                                children = {
                                    {
                                        type = "flow",
                                        direction = "vertical",
                                        style = "ingteb-flow-fill",
                                        children = self:GetSubGroupPanel(group),
                                    },
                                },
                            },
                        },
                    },
                }
            end
        ),
    }
end

function Class:ShowSelectionForAllItems()
    return self.Frame.add {type = "choose-elem-button", elem_type = "signal"}
end

return Class
