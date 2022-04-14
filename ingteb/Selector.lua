local gui = require("__flib__.gui-beta")
local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")

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
        MainGui = {
            get = function(self)
                return self.Player.gui.screen[Constants.ModName .. "." .. self.class.name]
            end,
        },
    }
)

function Class:Open(targets)
    self.Targets = Array:new(targets)
    local data = self:GetGui()
    local result = Helper.CreateFloatingFrameWithContent(
        self, data, {"ingteb-utility.selector"}, {
            buttons = {
                self.Filter == nil and {type = "empty-widget"} --
                or {
                    type = "textfield",
                    text = self.Filter,
                    style_mods = {maximal_width = 100, minimal_height = 28},
                    actions = {on_text_changed = {module = self.class.name, action = "Update"}},
                    ref = {"Filter"},
                },
                {
                    type = "sprite-button",
                    sprite = "search_white",
                    style = "frame_action_button",
                    actions = {on_click = {module = self.class.name, action = "Search"}},
                },
            },
        }
    )
    if result.Filter then result.Filter.focus() end
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    if message.action == "Closed" then
        self.Filter = nil
        self:Close()
    elseif message.action == "Click" then
        local commonKey = message.key or event.element.name
        local location = Helper.GetLocation(event.element)
        self.Filter = nil
        self:Close()
        if event.button == defines.mouse_button_type.left then
            self.Parent:PresentTargetByCommonKey(commonKey, message.module)
        elseif event.button == defines.mouse_button_type.right then
            self.Parent:SelectRemindorByCommonKey(commonKey, location)
        else
            dassert()
        end
    elseif message.action == "Search" then
        if self.Filter then
            self.Filter = nil
        else
            self.Filter = ""
        end
        self:Close()
        self:Open(self.Targets)
    elseif message.action == "Update" then
        self.Filter = event.element.text
        self:Close()
        self:Open(self.Targets)
    else
        dassert()
    end
end

function Class:OnSettingsChanged(event)
    -- dassert()   
end

function Class:GetGui()
    local lastValue = self.MissingSearchTexts
    self.MissingSearchTexts = nil
    local result = self:GetGuiInnerVariant()

    if self.MissingSearchTexts and lastValue ~= self.MissingSearchTexts then
        self.Parent.Player.print(
            {"ingteb-utility.missing-text-for-search-1", self.MissingSearchTexts}
        )
        self.Parent.Player.print({"ingteb-utility.missing-text-for-search-3"})
        log("self.MissingSearchTexts = " .. self.MissingSearchTexts)
    end

    return result
end

function Class:GetGuiInnerVariant()
    local result
    if self.Targets:Count() > 0 then
        result = self:GetTargetsGui()
    else
        result = self:GetAllItemsGui()
    end
    return result
end

function Class:Close() if self.MainGui then self.MainGui.destroy() end end

function Class:IsVisible(target)
    if self.Filter then
        local targetText = target.SearchText or target.Name
        return targetText:lower():find(self.Filter:lower())
    else
        if not target.SearchText then
            log(target.CommonKey)
            self.MissingSearchTexts = (self.MissingSearchTexts or 0) + 1
        end
        return true
    end
end

function Class:GetTargets()
    return self.Targets --
    :Where(function(goods) return self:IsVisible(goods) end) --
    :Select(
        function(target)
            if target.SpriteType == "fuel-category" then
                return {
                    type = "sprite-button",
                    sprite = target.SpriteName,
                    name = target.CommonKey,
                    tooltip = target.LocalisedName,
                    actions = {on_click = {module = self.class.name, action = "Click"}},
                }
            else
                return {
                    type = "choose-elem-button",
                    elem_type = target.SpriteType,
                    name = target.CommonKey,
                    elem_mods = {elem_value = target.Name, locked = true},
                    actions = {on_click = {module = self.class.name, action = "Click"}},
                }
            end
        end
    )

end

function Class:GetTargetsGui()
    return {
        type = "flow",
        direction = "vertical",
        children = {
            {
                type = "table",
                column_count = Constants.SelectorColumnCount,
                children = self:GetTargets(),
            },
            {type = "line", direction = "horizontal"},
            {type = "table", column_count = Constants.SelectorColumnCount},
        },

    }

end

function Class:RestoreFromSave(parent)
    self.Parent = parent
    self:Close()
end

function Class:GetGoodsPanel(goods)
    return {
        type = "sprite-button",
        sprite = goods.SpriteName,
        name = goods.CommonKey,
        tooltip = goods.LocalisedName,
        actions = {on_click = {module = self.class.name, action = "Click"}},
    }
end

function Class:GetSubGroupPanel(group, columnCount)
    return group:ToArray():Select(
        function(subgroup)
            local goods = subgroup --
            :Where(function(goods) return self:IsVisible(goods) end) --
            :Select(function(goods) return self:GetGoodsPanel(goods) end)
            if not goods:Any() then return end
            return {type = "table", column_count = columnCount, children = goods}
        end
    ) --
    :Where(function(subgroup) return subgroup end)
end

function Class:GetAllItemsGui()
    local selector = self.Parent.Database.Selector
    local groups = selector.Groups

    return {
        type = "tabbed-pane",
        tabs = groups:ToArray(
            function(group, name)
                local subGroup = self:GetSubGroupPanel(group, selector.ColumnCount)
                local caption = "[item-group=" .. name .. "]"
                if name == "fuel-category" then
                    caption = "[img=utility.slot_icon_fuel]"
                end
                return {
                    tab = {
                        type = "tab",
                        caption = caption,
                        -- style = "filter_group_tab",
                        style = subGroup:Any() and "ingteb-big-tab" or "ingteb-big-tab-disabled",
                        tooltip = {"item-group-name." .. name},
                        ignored_by_interaction = not subGroup:Any(),
                        -- style_mods = {font = "ingteb-font32"}
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
                                        children = subGroup,
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

function Class:new(parent) return self:adopt{Parent = parent} end

return Class
