require "core.debugSupport"
local mod_gui = require("mod-gui")
local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local Constants = require("Constants")

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"

local Class = {}

---@param guiElement table LuaGuiElement
---@return table GuiLocation
function Class.GetLocation(guiElement)
    if not guiElement then
        return
    elseif guiElement.location then
        return guiElement.location
    else
        return Class.GetLocation(guiElement.parent)
    end
end

function Class.GetActualType(type)
    if type == "item" or type == "fluid" or type == "technology" or type == "entity" or type
        == "recipe" then return type end
    if type == "tool" then return "technology" end
    return "entity"
end

function Class.FormatSpriteName(target)
    if target.name then return Class.GetActualType(target.type) .. "." .. target.name end
end

function Class.FormatRichText(target)
    return "[" .. Class.GetActualType(target) .. "=" .. target.name .. "]"
end

function Class.HasForce(type) return type == "technology" or type == "recipe" end

function Class.ShowFrame(player, name, create)
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

function Class.DeepEqual(a, b)
    if not a then return not b end
    if not b then return false end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end

    local keyCache = {}

    for key, value in pairs(a) do
        keyCache[key] = true
        if not Class.DeepEqual(value, b[key]) then return false end
    end

    for key, _ in pairs(b) do if not keyCache[key] then return false end end

    return true

end

local function EnsureMaxParameters(target, count)
    if #target <= count then return target end
    dassert(target[1] == "")
    local half = math.ceil(#target / 2)

    local result1 = { "" }
    for index = 2, half do table.insert(result1, target[index]) end

    local result2 = { "" }
    for index = half + 1, #target do table.insert(result2, target[index]) end

    return { "", EnsureMaxParameters(result1, count), EnsureMaxParameters(result2, count) }
end

local function StripArray(target)
    if target.object_name == "Array" then
        return target:Strip()
    else
        return target
    end
end

function Class.ScrutinizeLocalisationString(target)
    if type(target) ~= "table" then return target end
    for index = 2, #target do target[index] = Class.ScrutinizeLocalisationString(target[index]) end
    return StripArray(EnsureMaxParameters(target, 20))
end

function Class.SpriteStyleFromCode(code)
    return code == "active" and "ingteb-light-button" --
        or code == "not-researched" and "red_slot_button" --
        or code == "researching" and "yellow_slot_button" --
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
function Class.CreateFrameWithContent(moduleName, frame, content, caption, options)
    if not options then options = {} end
    local buttons = options.buttons or {}
    local result = gui.build(
        frame, {
        {
            type = "frame",
            direction = "vertical",
            name = Constants.ModName .. "." .. moduleName .. (options.subModule or ""),
            ref = { "Main" },
            style_mods = { padding = 0 },
            actions = {
                on_location_changed = {
                    module = moduleName,
                    subModule = options.subModule,
                    action = "Moved",
                },
                on_closed = {
                    module = moduleName,
                    subModule = options.subModule,
                    action = "Closed",
                },
            },
            children = {
                {
                    type = "flow",
                    name = "Header",
                    direction = "horizontal",
                    children = {
                        {
                            type = "label",
                            name = "Title",
                            caption = caption,
                            style = "frame_title",
                        },
                        {
                            type = "empty-widget",
                            name = "DragHandle",
                            style = "flib_titlebar_drag_handle",
                            ref = { "DragBar" },
                        },
                        {
                            type = "flow",
                            name = "Buttons",
                            direction = "horizontal",
                            children = buttons,
                        },
                        {
                            type = "sprite-button",
                            name = "CloseButtom",
                            sprite = "close_white",
                            tooltip = { "gui.close" },
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
function Class.CreateFloatingFrameWithContent(self, content, caption, options)
    if not options then options = {} end
    local moduleName = self.class.name
    local player = self.Player
    local global = self.PlayerGlobal

    local result = Class.CreateFrameWithContent(
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
function Class.CreatePopupFrameWithContent(self, content, caption, options)
    local parentScreen = self.Player.opened
    if parentScreen and parentScreen.valid and parentScreen.object_name == "LuaGuiElement" then
        self.ParentScreen = parentScreen
    end
    local isPopup = self.PlayerGlobal.IsPopup
    self.PlayerGlobal.IsPopup = true
    local result = Class.CreateFloatingFrameWithContent(self, content, caption, options)
    self.PlayerGlobal.IsPopup = isPopup
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
function Class.CreateLeftSideFrameWithContent(self, content, caption, --[[optioal]] options)
    if not options then options = {} end
    local moduleName = self.class.name
    local player = self.Player
    local result = Class.CreateFrameWithContent(
        moduleName, mod_gui.get_frame_flow(player), content, caption, options
    )
    return result
end

---create helper text from data lines as LocalisedString
--- ensures that resulting lists do not have more than 20 parameters (a restriction from factorio mod lib: https://lua-api.factorio.com/latest/Concepts.html#LocalisedString)
---@param top any LocalizedText that will be the head or then only result if there are no lines
---@param tail table Array of LocalizedText
---@return any LocalisedString
function Class.ConcatLocalisedText(top, tail)
    local lines = Array:new {}
    local function append(line)
        if line then
            lines:Append("\n")
            lines:Append(line)
        end
    end

    tail:Select(append)
    local result = top
    if lines:Any() then
        lines:InsertAt(1, "")
        result = { "", top, lines }
    end
    return Class.ScrutinizeLocalisationString(result)
end

function Class.CreatePrototypeProxy(target)
    local result = {}
    for key, value in pairs(target) do
        if key ~= "Prototype" and key ~= "Also" then
            result[key] = value
        end
    end

    local prototype = target.Prototype
    if prototype then
        if not result.type then
            result.type = prototype.object_name == "LuaRecipePrototype" and "recipe"
                or prototype.type
        end

        result.object_name_prototype = prototype.object_name

        local also = { "name", "localised_name", "localised_description", "group", "subgroup", "order" }
        for _, key in ipairs(also) do
            if not result[key] then result[key] = prototype[key] end
        end

        if target.Also then
            for _, key in ipairs(target.Also) do
                result[key] = prototype[key]
            end
        end
    end

    dassert(result.type)
    dassert(result.name)

    if not result.localised_name then result.localised_name = { "ingteb-name." .. result.type .. "-" .. result.name } end
    if not result.localised_description then result.localised_description = { "ingteb-descrition." .. result.type .. "-" .. result.name } end
    return result
end

function Class.CalculateHeaterRecipe(prototype)
    local fluidBoxes = Array:new(prototype.fluidbox_prototypes)
    local inBox--
    = fluidBoxes--
        :Where(--
            function(box)
                return box.filter
                    and (box.production_type == "input" or box.production_type == "input-output")
            end
        )--
        :Top(false, false)--
        .filter

    local outBox = fluidBoxes--
        :Where(function(box) return box.filter and box.production_type == "output" end)--
        :Top(false, false)--
        .filter

    local inEnergy = (outBox.default_temperature - inBox.default_temperature) * inBox.heat_capacity
    local outEnergy = (prototype.target_temperature - outBox.default_temperature)
        * outBox.heat_capacity

    local amount = 60 * prototype.max_energy_usage / (inEnergy + outEnergy)
    if prototype.burner_prototype and prototype.burner_prototype.effectivity and prototype.burner_prototype.effectivity ~= 1 then
        amount = amount / prototype.burner_prototype.effectivity
    end

    return Class.CreatePrototypeProxy { type = "Boiling",
        Prototype = prototype,
        sprite_type = "entity",
        hidden = true,
        ingredients = { { type = "fluid", amount = amount, name = inBox.name } },
        products = { { type = "fluid", amount = amount, name = outBox.name } },
        category = prototype.name,

    }
end

function Class.IsValidBoiler(prototype)
    local fluidBoxes = Array:new(prototype.fluidbox_prototypes)
    if not fluidBoxes then
        log {
            "mod-issue.boiler-without-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    end
    local inBoxes--
    = fluidBoxes--
        :Where(
            function(box)
                return box.production_type == "input" or box.production_type == "input-output"
            end
        ) --
    local outBoxes = fluidBoxes--
        :Where(function(box) return box.production_type == "output" end) --

    local result = true
    if not inBoxes or inBoxes:Count() ~= 1 then
        log {
            "mod-issue.boiler-no-unique-input-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    elseif not inBoxes[1].filter then
        log {
            "mod-issue.boiler-generic-input-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    end

    if not outBoxes or outBoxes:Count() ~= 1 then
        log {
            "mod-issue.boiler-no-unique-output-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    elseif not outBoxes[1].filter then
        log {
            "mod-issue.boiler-generic-output-fluidbox",
            prototype.localised_name,
            prototype.type .. "." .. prototype.name,
        }
        return
    end

    return result
end

function Class.GetNestedProperty(prototype, path)
    local result = prototype
    if not result then return end
    if type(path) == "table" then
        for _, value in ipairs(path) do
            result = Class.GetNestedProperty(result, value)
            if not result then return end
        end
        return result
    else
        return result[path]
    end
end

function Class.GetNestedPath(path)
    if type(path) == "table" then
        return Array
            :new(path)
            :Select(function(item) return Class.GetNestedPath(item) end)
            :Stringify(".")
    else
        dassert(type(path) == "string")
        return path
    end
end

return Class
