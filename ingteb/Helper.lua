local mod_gui = require("mod-gui")
local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary

local Helper = {}

---@param guiElement table LuaGuiElement
---@return table GuiLocation
function Helper.GetLocation(guiElement)
    if not guiElement then
        return
    elseif guiElement.location then
        return guiElement.location
    else
        return Helper.GetLocation(guiElement.parent)
    end
end

function Helper.GetActualType(type)
    if type == "item" or type == "fluid" or type == "technology" or type == "entity" or type
        == "recipe" then return type end
    if type == "tool" then return "technology" end
    return "entity"
end

function Helper.FormatSpriteName(target)
    if target.name then return Helper.GetActualType(target.type) .. "." .. target.name end
end

function Helper.FormatRichText(target)
    return "[" .. Helper.GetActualType(target) .. "=" .. target.name .. "]"
end

function Helper.HasForce(type) return type == "technology" or type == "recipe" end

function Helper.ShowFrame(player, name, create)
    local frame = player.gui.screen
    local main = frame[name]
    if main then
        main.clear()
    else
        main = frame.add {
            type = "frame",
            name = name,
            direction = "vertical",
            style = "ingteb-main-frame",
        }
    end
    create(main)
    player.opened = main
    if global.Location[name] then
        main.location = global.Location[name]
    else
        main.force_auto_center()
    end
    return main
end

function Helper.OnClose(name, frame) global.Location[name] = frame.location end

function Helper.DeepEqual(a, b)
    if not a then return not b end
    if not b then return false end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end

    local keyCache = {}

    for key, value in pairs(a) do
        keyCache[key] = true
        if not Helper.DeepEqual(value, b[key]) then return false end
    end

    for key, _ in pairs(b) do if not keyCache[key] then return false end end

    return true

end

function Helper.SpriteStyleFromCode(code)
    return code == true and "ingteb-light-button" --
    or code == false and "red_slot_button" --
    or "slot_button"
end

---Create frame and add content
--- Provided actions: location_changed and closed
---@param moduleName string
---@param frame table LuaGuiElement where gui will be added
---@param content table flib.GuiBuildStructure
---@param caption any LocalisedString
---@param options table
--- buttons table[] flib.GuiBuildStructure
--- subModule string name of the subModule for location and actions 
---@return table LuaGuiElement references and subtables, built based on the values of ref throughout the GuiBuildStructure.
function Helper.CreateFrameWithContent(moduleName, frame, content, caption, options)
    if not options then options = {} end
    local buttons = options.buttons or {}
    local result = gui.build(
        frame, {
            {
                type = "frame",
                direction = "vertical",
                name = moduleName .. (options.subModule or ""),
                ref = {"Main"},
                actions = {
                    on_location_changed = {action = "Moved"},
                    on_closed = {
                        module = moduleName,
                        subModule = options.subModule,
                        action = "Closed",
                    },
                },
                children = {
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {type = "label", caption = caption},
                            {
                                type = "empty-widget",
                                style = "flib_titlebar_drag_handle",
                                ref = {"DragBar"},
                            },
                            {type = "flow", direction = "horizontal", children = buttons},
                            {
                                type = "sprite-button",
                                sprite = "utility/close_white",
                                tooltip = {"gui.close"},
                                actions = {
                                    on_click = {
                                        module = moduleName,
                                        subModule = options.subModule,
                                        action = "Closed",
                                    },
                                },
                                style = "frame_action_button",
                            },
                        },
                    },
                    content,
                },
            },
        }
    )

    if not frame.parent and frame.name == "screen" then result.DragBar.drag_target = result.Main end
    return result
end

---Create floating frame and add content
--- Provided actions: location_changed and closed
---@param self table ingteb-module
---@param content table flib.GuiBuildStructure
---@param caption any LocalisedString
---@param options table
--- buttons table[] flib.GuiBuildStructure
--- subModule string name of the subModule for location and actions 
---@return table LuaGuiElement references and subtables, built based on the values of ref throughout the GuiBuildStructure.
function Helper.CreateFloatingFrameWithContent(self, content, caption, options)
    if not options then options = {} end
    local moduleName = self.class.name
    local player = self.Player
    local global = self.Global

    local result = Helper.CreateFrameWithContent(
        moduleName, player.gui.screen, content, caption, options
    )
    player.opened = result.Main

    local locationTag = moduleName .. (options.subModule or "")
    if global.Location[locationTag] then
        result.Main.location = global.Location[locationTag]
    else
        result.Main.force_auto_center()
        global.Location[locationTag] = result.Main.location
    end
    return result
end

---Create popup frame and add content
--- Provided actions: location_changed and closed
---@param self table ingteb-module
---@param content table flib.GuiBuildStructure
---@param caption any LocalisedString
---@param options table
--- buttons table[] flib.GuiBuildStructure
--- subModule string name of the subModule for location and actions 
---@return table LuaGuiElement references and subtables, built based on the values of ref throughout the GuiBuildStructure.
function Helper.CreatePopupFrameWithContent(self, content, caption, options)
    self.ParentScreen = self.Player.opened
    local isPopup = self.Global.IsPopup
    self.Global.IsPopup = true
    local result = Helper.CreateFloatingFrameWithContent(self, content, caption, options)
    self.Global.IsPopup = isPopup
    return result
end

---Create floating frame and add content
--- Provided actions: closed
---@param self table ingteb-module
---@param content table flib.GuiBuildStructure
---@param caption any LocalisedString
---@param options table
--- buttons table[] flib.GuiBuildStructure
--- subModule string name of the subModule for location and actions 
---@return table LuaGuiElement references and subtables, built based on the values of ref throughout the GuiBuildStructure.
function Helper.CreateLeftSideFrameWithContent(self, content, caption, options)
    if not options then options = {} end
    local moduleName = self.class.name
    local player = self.Player
    local result = Helper.CreateFrameWithContent(
        moduleName, mod_gui.get_frame_flow(player), content, caption, options
    )
    return result
end

return Helper
