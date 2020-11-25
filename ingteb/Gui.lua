local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Database = require("ingteb.Database")

local function CreateSpriteAndRegister(frame, target)
    local result

    local tooltip = target and target.HelperText
    local sprite = target and target.SpriteName
    local number = target and target.NumberOnSprite
    local show_percent_for_small_numbers = target and target.UsePercentage
    local spriteStyleCode = target and target.SpriteStyle
    local style = spriteStyleCode == true and "ingteb-light-button" --
    or spriteStyleCode == false and "red_slot_button" --
    or "slot_button"

    if target then
        result = frame.add {
            type = "sprite-button",
            tooltip = tooltip,
            sprite = sprite,
            number = number,
            show_percent_for_small_numbers = show_percent_for_small_numbers,
            style = style,
        }
    else
        result = frame.add {type = "sprite-button", style = style}
    end

    global.Current.Links[result.index] = target and target.MainObject
    if target and (target.IsDynamic or target.HasLocalisedDescriptionPending) then
        if target and target.object_name == "BonusSet" then --
            local s = 2 --
        end
        global.Current.Gui:AppendForKey(target, result)
    end
    return result
end

local maximalCount = 6

local function CreateRecipeLinePart(frame, target, count, isInput)
    local scrollFrame = frame
    if target:Count() > count then
        scrollFrame = frame.add {
            type = "scroll-pane",
            direction = "horizontal",
            vertical_scroll_policy = "never",
            style = "ingteb-scroll-6x1",
        }
    end

    local subPanel = scrollFrame.add {
        type = "flow",
        direction = "horizontal",
        style = isInput and "ingteb-flow-right" or nil,
    }

    target:Select(
        function(item)
            return CreateSpriteAndRegister(subPanel, item)
        end
    )

    if isInput then return end

    for _ = target:Count() + 1, count do --
        subPanel.add {type = "sprite", style = "ingteb-un-button"}
    end

end

local function CreateRecipeLine(frame, target, inCount, outCount)
    local subFrame = frame.add {type = "flow", direction = "horizontal"}

    CreateRecipeLinePart(subFrame, target.Input, math.min(inCount, maximalCount), true)

    local properties = subFrame.add {type = "flow", direction = "horizontal"}
    properties.add {type = "sprite", sprite = "utility/go_to_arrow"}
    CreateSpriteAndRegister(properties, target.Technology)
    CreateSpriteAndRegister(properties, target)
    CreateSpriteAndRegister(
        properties, {SpriteName = "utility/clock", NumberOnSprite = target.energy}
    )
    properties.add {type = "sprite", sprite = "utility/go_to_arrow"}

    CreateRecipeLinePart(subFrame, target.Output, math.min(outCount, maximalCount), false)
end

local function CreateCraftingGroupPanel(frame, target, category, inCount, outCount)
    frame.add {type = "line", direction = "horizontal"}

    local workersPanel = frame.add {
        type = "flow",
        style = "ingteb-flow-centered",
        direction = "horizontal",
    }

    local workers = target[1].Database.Proxies.Category[category].Workers
    workers:Select(function(worker) return CreateSpriteAndRegister(workersPanel, worker) end)

    frame.add {type = "line", direction = "horizontal"}

    target:Select(function(recipe) CreateRecipeLine(frame, recipe, inCount, outCount) end)

    frame.add {type = "line", direction = "horizontal"}
end

local function CreateCraftingGroupsPanel(frame, target, headerSprites)
    if not target or not target:Any() then return end

    local subFrame = frame.add {
        type = "frame",
        horizontal_scroll_policy = "never",
        direction = "vertical",
    }

    local labelFlow = subFrame.add {
        type = "flow",
        direction = "horizontal",
        style = "ingteb-flow-centered",
    }

    headerSprites:Select(function(sprite) labelFlow.add {type = "sprite", sprite = sprite} end)

    local inCount = target:Select(
        function(group)
            return group:Select(function(recipe) return recipe.Input:Count() end):Max()
        end
    ):Max()

    local outCount = target:Select(
        function(group)
            return group:Select(function(recipe) return recipe.Output:Count() end):Max()
        end
    ):Max()

    target:Select(
        function(recipes, category)
            CreateCraftingGroupPanel(subFrame, recipes, category, inCount, outCount)
        end
    )
end

local function CreateMainPanel(frame, target)
    frame.caption = target.LocalisedName

    local scrollframe = frame.add {
        type = "scroll-pane",
        horizontal_scroll_policy = "never",
        direction = "vertical",
        name = "frame",
    }

    target:SortAll()

    local mainFrame = scrollframe
    local columnCount = (target.RecipeList:Any() and 1 or 0) + --
    (target.UsedBy:Any() and 1 or 0) + --
    (target.CreatedBy:Any() and 1 or 0)

    if columnCount > 1 then
        mainFrame = scrollframe.add {type = "frame", direction = "horizontal", name = "frame"}
    end

    if columnCount == 0 then
        local none = mainFrame.add {type = "frame", direction = "horizontal"}
        none.add {
            type = "label",
            caption = "[img=utility/crafting_machine_recipe_not_unlocked][img=utility/go_to_arrow]",
        }

        CreateSpriteAndRegister(none, target)

        none.add {
            type = "label",
            caption = "[img=utility/go_to_arrow][img=utility/crafting_machine_recipe_not_unlocked]",
        }

        return
    end

    CreateCraftingGroupsPanel(mainFrame, target.RecipeList, Array:new{target.SpriteName, "factorio"})

    CreateCraftingGroupsPanel(
        mainFrame, target.UsedBy,
            Array:new{target.SpriteName, "utility/go_to_arrow", "utility/missing_icon"}
    )

    CreateCraftingGroupsPanel(
        mainFrame, target.CreatedBy,
            Array:new{"utility/missing_icon", "utility/go_to_arrow", target.SpriteName}
    )

end

local result = {}

function result.SelectTarget()
    return Helper.ShowFrame(
        "Selector", function(frame)
            frame.caption = "select"
            frame.add {type = "choose-elem-button", elem_type = "signal"}
        end
    )
end

function result.Main(target)
    assert(target.Prototype)
    return Helper.ShowFrame(
        "Main", function(frame)
            assert(target.object_name == "Item")
            return CreateMainPanel(frame, target)
        end
    )
end

return result
