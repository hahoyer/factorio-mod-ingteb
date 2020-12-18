local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local UI = require("core.UI")
local class = require("core.class")
local MiningRecipe = require("ingteb.MiningRecipe")
local Recipe = require("ingteb.Recipe")
local Technology = require("ingteb.Technology")
local SpritorClass = require("ingteb.Spritor")
local Bonus = require("ingteb.Bonus")

local Presentator = {}

local Spritor = SpritorClass:new("Presentator")

local function CreateContentPanel(frame, headerSprites, tooltip)
    local subFrame = frame.add {
        type = "frame",
        horizontal_scroll_policy = "never",
        direction = "vertical",
    }

    local headerFlow = subFrame.add {
        type = "flow",
        name = "headerFlow",
        direction = "horizontal",
        style = "ingteb-flow-centered",
    }

    headerFlow.add {
        type = "label",
        name = "headerSprites",
        caption = headerSprites,
        tooltip = tooltip,
        style = "ingteb-big-label",
    }

    subFrame.add {type = "line", direction = "horizontal"}

    return subFrame
end

local maximalCount = 6

local function CreateRecipeLine(frame, target, inCount, outCount)
    local subFrame = frame.add {type = "flow", direction = "horizontal"}

    Spritor:CreateLinePart(subFrame, target.Input, inCount, true)

    local properties = subFrame.add {type = "flow", direction = "horizontal"}
    properties.add {type = "sprite", sprite = "utility/go_to_arrow"}
    Spritor:CreateSpriteAndRegister(
        properties, target.Technology
            or {SpriteName = "factorio", HelperText = {"ingteb-utility.initial-technology"}}
    )
    Spritor:CreateSpriteAndRegister(properties, target)
    Spritor:CreateSpriteAndRegister(
        properties, {SpriteName = "utility/clock", NumberOnSprite = target.Time}
    )
    properties.add {type = "sprite", sprite = "utility/go_to_arrow"}

    Spritor:CreateLinePart(subFrame, target.Output, outCount, false)
end

local function CreateWorkersPanel(frame, workers, columnCount)
    local workersCount = workers:Count()
    local lines = math.ceil(workersCount / columnCount)
    local potentialWorkerCount = lines * columnCount
    local dummiesRequired = potentialWorkerCount - workersCount
    local dummyColumnsLeft = math.ceil((dummiesRequired) / 2)

    local workersPanel = frame.add {
        type = "table",
        column_count = columnCount + 1,
        direction = "horizontal",
    }

    local position = 0
    workers:Select(
        function(worker)
            if position == 0 then
                workersPanel.add {type = "sprite", sprite = "utility/change_recipe"}
            end
            if lines == 1 and position == 0 then
                Spritor:DummyTiles(workersPanel, dummyColumnsLeft)
                position = position + dummyColumnsLeft
            end
            Spritor:CreateSpriteAndRegister(workersPanel, worker)
            position = position + 1
            if position >= columnCount then
                position = 0
                lines = lines - 1
            end
        end
    )
end

local function CreateCraftingGroupPanel(frame, target, category, inCount, outCount)
    assert(release or type(category) == "string")
    inCount = math.min(inCount, maximalCount)
    outCount = math.min(outCount, maximalCount)

    local workers = target[1].Database:GetCategory(category).Workers

    CreateWorkersPanel(frame, workers, inCount + outCount + 3)

    frame.add {type = "line", direction = "horizontal"}

    if target:Count() < settings.player["ingteb_group-tab-threshold"].value then
        target:Select(function(recipe) CreateRecipeLine(frame, recipe, inCount, outCount) end)
    else
        local groups = target:ToGroup(
            function(value) return {Key = value.Group.name, Value = value} end
        ):ToArray()
        local groupPanel = groups:Count() > 1 and frame.add {type = "tabbed-pane"} or frame
        groups:Select(
            function(value)
                local group = value[1].Group
                local frame = groupPanel.add {type = "flow", direction = "vertical"}

                if groups:Count() > 1 then
                    local tab = groupPanel.add {
                        type = "tab",
                        caption = "[item-group=" .. group.name .. "]",
                        tooltip = group.localised_name,
                        style = "ingteb-medium-tab",
                    }
                    groupPanel.add_tab(tab, frame)
                end

                if value:Count() < settings.player["ingteb_subgroup-tab-threshold"].value then
                    value:Select(
                        function(recipe)
                            CreateRecipeLine(frame, recipe, inCount, outCount)
                        end
                    )
                else
                    local subGroups = value:ToGroup(
                        function(value)
                            return {Key = value.SubGroup.name, Value = value}
                        end
                    ):ToArray() --
                    local groupPanel = subGroups:Count() > 1 and frame.add {type = "tabbed-pane"}
                                           or frame
                    subGroups:Select(
                        function(value)
                            local group = value[1].SubGroup
                            local caption = group.name
                            if value[1] and value[1].Output[1] then
                                local main = value[1].Output[1]
                                caption = main.RichTextName
                            end
                            local subFrame = groupPanel.add {type = "flow", direction = "vertical"}

                            if subGroups:Count() > 1 then
                                local tab = groupPanel.add {
                                    type = "tab",
                                    caption = caption,
                                    tooltip = group.localised_name,
                                    style = "ingteb-medium-tab",
                                }
                                groupPanel.add_tab(tab, subFrame)
                            end

                            value:Select(
                                function(recipe)
                                    CreateRecipeLine(subFrame, recipe, inCount, outCount)
                                end
                            )
                        end
                    )
                end
            end
        )

    end

    frame.add {type = "line", direction = "horizontal"}
end

local function CreateCraftingGroupsPanel(frame, target, headerSprites, tooltip)
    if not target or not target:Any() then return end
    assert(release or type(target:Top().Key) == "string")
    assert(
        release or target:Top().Value[1].class == Recipe --
        or target:Top().Value[1].class == MiningRecipe
    )

    local subFrame = CreateContentPanel(frame, headerSprites, tooltip)

    local inCount = target:Select(
        function(group)
            return group:Select(function(recipe) return recipe.Input:Count() end):Maximum()
        end
    ):Maximum()

    local outCount = target:Select(
        function(group)
            return group:Select(function(recipe) return recipe.Output:Count() end):Maximum()
        end
    ):Maximum()

    target:Select(
        function(recipes, category)
            assert(release or type(category) == "string")
            CreateCraftingGroupPanel(subFrame, recipes, category, inCount, outCount)
        end
    )
end

local function CreateTechnologyEffectsPanel(frame, target)
    local effects = target.Effects
    if not effects then return end

    local frame = CreateContentPanel(
        frame, {"", target.RichTextName, " ", {"gui-technology-preview.effects"}}
    )

    local ingredientsLine = frame.add {type = "flow", direction = "horizontal"}
    ingredientsLine.add {type = "sprite", sprite = "utility/change_recipe"}

    local ingredientsPanel = ingredientsLine.add {
        type = "flow",
        direction = "horizontal",
        style = "ingteb-flow-centered",
    }

    target.Ingredients:Select(function(stack) Spritor:CreateSprite(ingredientsPanel, stack) end)
    frame.add {type = "line", direction = "horizontal"}

    if not effects:Any() then
        local frame = frame.add {type = "flow", direction = "horizontal"}
        Spritor:CreateSpriteAndRegister(frame, target)

        frame.add {
            type = "label",
            caption = "[img=utility/go_to_arrow][img=utility/crafting_machine_recipe_not_unlocked]",
        }

        return
    end

    assert(release or effects[1].class == Recipe or effects[1].class == Bonus)

    local inCount = effects:Select(function(recipe) return recipe.Input:Count() end):Maximum()
    local outCount = effects:Select(function(recipe) return recipe.Output:Count() end):Maximum()

    local frame = frame.add {type = "flow", direction = "vertical"}
    effects:Select(
        function(effekt)
            if effekt.class == Recipe then
                CreateRecipeLine(frame, effekt, inCount, outCount)
            else
                local frame = frame.add {type = "flow", direction = "horizontal"}
                Spritor:CreateSpriteAndRegister(frame, target)
                frame.add {type = "label", caption = "[img=utility/go_to_arrow]"}
                Spritor:CreateSpriteAndRegister(frame, effekt)
            end
        end
    )
end

local function CreateRecipePanel(frame, target)
    if target.class.name ~= "Recipe" then return end

    local frame = CreateContentPanel(frame, {"", target.RichTextName}, "Information about the recipe")
    local inCount = math.min(target.Input:Count(), maximalCount)
    local outCount = math.min(target.Output:Count(), maximalCount)
    local workers = target.Category.Workers
    CreateWorkersPanel(frame, workers, inCount + outCount + 3)
    frame.add {type = "line", direction = "horizontal"}
    CreateRecipeLine(frame, target, inCount, outCount)
end

local function Extend(items, nextItems)
    local itemsSoFar = items:Clone()
    repeat
        local newItems = Array:new()
        local isRepeatRequired
        items:Select(
            function(item)
                nextItems(item):Select(
                    function(item)
                        if not itemsSoFar:Contains(item) then
                            newItems:Append(item)
                            itemsSoFar:Append(item)
                            isRepeatRequired = true
                        end
                    end
                )
            end
        )
        items = newItems
    until not isRepeatRequired
    return itemsSoFar
end

local function CreateTechnologyList(frame, target)
    local ingredientsCount = target --
    :Select(function(value) return value.Ingredients:Count() end):Maximum()
    target:ToGroup(
        function(value)

            local key = value.Ingredients --
            :Select(function(stack) return stack.CommonKey end) --
            :Stringify(",")
            return {Key = key, Value = value}
        end
    ) --
    :Select(
        function(values)
            local frame = frame.add {type = "flow", direction = "horizontal"}

            Spritor:DummyTiles(frame, ingredientsCount - values[1].Ingredients:Count())

            values[1].Ingredients:Select(
                function(stack) Spritor:CreateSpriteAndRegister(frame, stack) end
            )

            frame.add {type = "label", caption = "[img=utility/go_to_arrow]"}

            local technologiesPanel = frame.add {type = "table", column_count = 2}
            values:Select(
                function(target)
                    local frame = technologiesPanel.add {type = "frame", direction = "horizontal"}
                    Spritor:CreateSpriteAndRegister(frame, target)
                    Spritor:CreateSprite(
                        frame, {SpriteName = "item/lab", NumberOnSprite = target.Amount}
                    )
                    Spritor:CreateSprite(
                        frame, {SpriteName = "utility/clock", NumberOnSprite = target.Time}
                    )
                end
            )
        end
    )
end

local function CreateTechnologiesPanel(frame, target, headerSprites, isPrerequisites)
    if not target or not target:Any() then return end
    assert(release or target:Top().class == Technology)

    local frame = CreateContentPanel(frame, headerSprites, isPrerequisites and "Techonlogies required for this technology" or "Techonlogies this technology enables")

    local targetExtendend = Extend(
        target, function(technology)
            if isPrerequisites then
                return technology.Prerequisites
            else
                return technology.Enables
            end
        end
    ) --
    :Where(function(technology) return not target:Contains(technology) end)

    CreateTechnologyList(frame, target)
    frame.add {type = "line", direction = "horizontal"}
    CreateTechnologyList(frame, targetExtendend)

end

local function CheckedTabifyColumns(frame, mainFrame, target, columnCount)
    local maximalColumCount = settings.player["ingteb_column-tab-threshold"].value
    if maximalColumCount == 0 then maximalColumCount = columnCount end

    if columnCount > maximalColumCount then
        local tabOrder = target.TabOrder
        if not tabOrder then
            tabOrder = Array:FromNumber(columnCount)
            target.TabOrder = tabOrder
        end

        tabOrder:Select(
            function(tabIndex, order)
                if order > maximalColumCount then
                    frame.caption --
                    = {
                        "",
                        frame.caption, --
                        " >>> [" .. mainFrame.children[tabIndex].headerFlow.headerSprites.caption
                            .. "]",
                    }
                    mainFrame.children[tabIndex].visible = false
                else
                    mainFrame.children[tabIndex].headerFlow.add {
                        type = "sprite-button",
                        sprite = "hide-this-column",
                        name = order,
                    }
                end
            end
        )
        global.Links.Presentator[frame.index] = target.ClickTarget

    end

end

function Presentator:Close() Spritor:Close() end

function Presentator:RefreshMainInventoryChanged(dataBase)
    Spritor:RefreshMainInventoryChanged(dataBase)
end

function Presentator:RefreshStackChanged(dataBase) end

function Presentator:RefreshResearchChanged(dataBase) Spritor:RefreshResearchChanged(dataBase) end

function Presentator:new(frame, target)
    Spritor.DynamicElements = Dictionary:new() --
    global.Links.Presentator = {}
    frame.caption = target.LocalisedName

    local scrollframe = frame.add {
        type = "scroll-pane",
        horizontal_scroll_policy = "never",
        direction = "vertical",
        name = "frame",
    }

    target:SortAll()
    assert(
        release or not target.RecipeList or not next(target.RecipeList)
            or type(next(target.RecipeList)) == "string"
    )
    assert(
        release or not target.UsedBy or not next(target.UsedBy) or type(next(target.UsedBy))
            == "string"
    )
    assert(

       
            release or not target.CreatedBy or not next(target.CreatedBy)
                or type(next(target.CreatedBy)) == "string"
    )

    local mainFrame = scrollframe
    local columnCount --
    = (target.RecipeList and target.RecipeList:Any() and 1 or 0) --
          + (target.class == Recipe and 1 or 0) --
          + (target.Prerequisites and target.Prerequisites:Any() and 1 or 0) --
          + (target.Effects and target.Effects:Any() and 1 or 0) --
          + (target.Enables and target.Enables:Any() and 1 or 0) --
          + (target.UsedBy and target.UsedBy:Any() and 1 or 0) --
          + (target.CreatedBy and target.CreatedBy:Any() and 1 or 0) --

    if columnCount > 1 then
        mainFrame = scrollframe.add {type = "frame", direction = "horizontal", name = "frame"}
    end

    if columnCount == 0 then
        local none = mainFrame.add {type = "frame", direction = "horizontal"}
        none.add {
            type = "label",
            caption = "[img=utility/crafting_machine_recipe_not_unlocked][img=utility/go_to_arrow]",
        }

        Spritor:CreateSpriteAndRegister(none, target)

        none.add {
            type = "label",
            caption = "[img=utility/go_to_arrow][img=utility/crafting_machine_recipe_not_unlocked]",
        }

        return
    end

    CreateTechnologiesPanel(
        mainFrame, target.Prerequisites,
            "[img=utility/missing_icon][img=utility/go_to_arrow]" .. target.RichTextName, true
    )

    CreateTechnologyEffectsPanel(mainFrame, target)
    CreateRecipePanel(mainFrame, target)

    CreateTechnologiesPanel(
        mainFrame, target.Enables,
            target.RichTextName .. "[img=utility/go_to_arrow][img=utility/missing_icon]", false
    )

    CreateCraftingGroupsPanel(
        mainFrame, target.RecipeList, target.RichTextName .. "[img=utility/change_recipe]", "Recipes this machine can handle"
    )

    CreateCraftingGroupsPanel(
        mainFrame, target.CreatedBy,
            "[img=utility/missing_icon][img=utility/go_to_arrow]" .. target.RichTextName, "Recipes that produces this item."
    )

    CreateCraftingGroupsPanel(
        mainFrame, target.UsedBy,
            target.RichTextName .. "[img=utility/go_to_arrow][img=utility/missing_icon]", "Recipes this item uses a ingredience."
    )

    CheckedTabifyColumns(frame, mainFrame, target, columnCount)
end

return Presentator
