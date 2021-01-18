local Constants = require("Constants")
local gui = require("__flib__.gui-beta")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local MiningRecipe = require("ingteb.MiningRecipe")
local Recipe = require("ingteb.Recipe")
local Technology = require("ingteb.Technology")
local SpritorClass = require("ingteb.Spritor")
local Bonus = require("ingteb.Bonus")
local Entity = require("ingteb.Entity")

local Class = class:new(
    "Presentator", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
        Database = {get = function(self) return self.Parent.Database end},
    }
)

local Spritor

function Class:new(parent)
    local self = self:adopt{Parent = parent}
    Spritor = SpritorClass:new(self)
    return self
end

local nextId = 0
local function GetNextId()
    nextId = nextId + 1
    return nextId
end

---Create the header for content
---@param headerSprites string rich text and/or localised string
---@param tooltip string rich text and/or localised string
---@return table GuiStructure the GuiStructure
local function GetContentPanel(headerSprites, tooltip, data)
    local result = {
        type = "frame",
        direction = "vertical",
        children = Array:new{
            {
                type = "flow",
                name = "headerFlow",
                direction = "horizontal",
                style = "ingteb-flow-centered",
                children = {
                    {
                        type = "label",
                        name = "headerSprites",
                        caption = headerSprites,
                        tooltip = tooltip,
                        style = "ingteb-big-label",
                    },
                },
            },
            {type = "line", direction = "horizontal"},
        }:Concat(data),
    }
    return result
end

local maximalCount = 6

local function GetRecipeLine(target, inCount, outCount)
    return {
        type = "flow",
        name = "GetRecipeLine " .. GetNextId(),
        direction = "horizontal",
        children = {
            Spritor:GetLinePart(target.Input, inCount, true),
            {
                type = "flow",
                name = "GetRecipeLine inner " .. GetNextId(),
                direction = "horizontal",
                children = {
                    {type = "sprite", sprite = "utility/go_to_arrow"},
                    Spritor:GetSpriteButtonAndRegister(
                        target.Technology
                            or {
                                SpriteName = "factorio",
                                HelperText = {"ingteb-utility.initial-technology"},
                            }
                    ),
                    Spritor:GetSpriteButtonAndRegister(target),
                    Spritor:GetSpriteButtonAndRegister(
                        {SpriteName = "utility/clock", NumberOnSprite = target.Time}
                    ),
                    {type = "sprite", sprite = "utility/go_to_arrow"},
                },
            },
            Spritor:GetLinePart(target.Output, outCount, false),
        },
    }

end

local function GetWorkersPanel(workers, columnCount)
    local workersCount = workers:Count()
    local lines = math.ceil(workersCount / columnCount)
    local potentialWorkerCount = lines * columnCount
    local dummiesRequired = potentialWorkerCount - workersCount
    local dummyColumnsLeft = math.ceil((dummiesRequired) / 2)

    local workersPanelData = Array:new{}

    local position = 0
    workers:Select(
        function(worker)

            if position == 0 then
                workersPanelData:Append{
                    type = "sprite",
                    sprite = "utility/change_recipe",
                    tooltip = {"ingteb-utility.workers-for-recipes"},
                }
            end
            if lines == 1 and position == 0 then
                workersPanelData:AppendMany(Spritor:GetTiles(dummyColumnsLeft))
                position = position + dummyColumnsLeft
            end
            workersPanelData:Append(Spritor:GetSpriteButtonAndRegister(worker))
            position = position + 1
            if position >= columnCount then
                position = 0
                lines = lines - 1
            end
        end
    )

    return {
        type = "table",
        column_count = columnCount + 1,
        direction = "horizontal",
        children = workersPanelData,
    }

end

local function GetTechnologyEffectsData(target)
    local effects = target.Effects

    if not effects:Any() then
        return {
            type = "flow",
            name = "GetTechnologyEffectsData no effects " .. GetNextId(),
            direction = "horizontal",
            children = Spritor:GetSpriteButtonAndRegister(target),
            {
                type = "label",
                caption = "[img=utility/go_to_arrow][img=utility/crafting_machine_recipe_not_unlocked]",
            },
        }

    end

    dassert(effects[1].class == Recipe or effects[1].class == Bonus)

    local inCount = effects:Select(function(recipe) return recipe.Input:Count() end):Maximum()
    local outCount = effects:Select(function(recipe) return recipe.Output:Count() end):Maximum()

    return {
        type = "flow",
        name = "GetTechnologyEffectsData " .. GetNextId(),
        direction = "vertical",
        children = effects:Select(
            function(effekt)
                if effekt.class == Recipe then
                    return GetRecipeLine(effekt, inCount, outCount)
                else
                    return {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            Spritor:GetSpriteButtonAndRegister(target),
                            {type = "label", caption = "[img=utility/go_to_arrow]"},
                            Spritor:GetSpriteButtonAndRegister(effekt),
                        },
                    }
                end
            end
        ),
    }

end

local function GetTechnologyEffectsPanel(target)
    if not target or not target.Effects then return {} end

    return {
        GetContentPanel(
            target.RichTextName .. "[img=effects]", --
            {"gui-technology-preview.effects"}, --
            {
                {
                    type = "flow",
                    name = "GetTechnologyEffectsPanel " .. GetNextId(),
                    direction = "horizontal",
                    children = {
                        {
                            type = "sprite",
                            sprite = "utility/change_recipe",
                            tooltip = {"ingteb-utility.technology-research-ingredients"},
                        },
                        {
                            type = "flow",
                            name = "GetTechnologyEffectsPanel inner " .. GetNextId(),
                            direction = "horizontal",
                            style = "ingteb-flow-centered",
                            children = target.Ingredients:Select(
                                function(stack)
                                    return Spritor:GetSpriteButton(
                                        stack.Goods:CreateStack{
                                            value = stack.Amounts.value
                                                * target.Prototype.research_unit_count,
                                        }
                                    )
                                end
                            ):Concat{
                                Spritor:GetSpriteButton{
                                    SpriteName = "utility/clock",
                                    NumberOnSprite = target.Time,
                                },
                            },
                        },
                    },
                },
                {type = "line", direction = "horizontal"},
                GetTechnologyEffectsData(target),
            }
        ),
    }

end

local function GetSubGroupTabPanel(subGroup, recipeLines)
    local group = subGroup[1].SubGroup
    local caption = group.name
    if subGroup and subGroup[1].Output[1] then
        local main = subGroup[1].Output[1]
        caption = main.RichTextName
    end
    return {
        tab = {
            type = "tab",
            name = "GetSubGroupTabPanel " .. GetNextId(),
            caption = caption,
            tooltip = group.localised_name,
            style = "ingteb-medium-tab",
        },
        content = recipeLines,
    }
end

local function GetSubGroupPanelContent(target, inCount, outCount)
    return {
        type = "flow",
        direction = "vertical",
        name = "GetSubGroupPanelContent " .. GetNextId(),
        children = target:Select(
            function(recipe) return GetRecipeLine(recipe, inCount, outCount) end
        ),
    }
end

function Class:GetGroupPanelContent(value, inCount, outCount)
    if value:Count()
        < settings.get_player_settings(self.Player)["ingteb_subgroup-tab-threshold"].value then
        return {
            type = "flow",
            direction = "vertical",
            name = "GetGroupPanelContent " .. GetNextId(),
            children = value:Select(
                function(recipe) return GetRecipeLine(recipe, inCount, outCount) end
            ),
        }
    end

    local subGroups = value:ToGroup(
        function(value) return {Key = value.SubGroup.name, Value = value} end
    ):ToArray() --

    if subGroups:Count() == 1 then
        return GetSubGroupPanelContent(subGroups[1], inCount, outCount)
    end

    return {
        type = "tabbed-pane",
        name = "GetGroupPanelContent " .. GetNextId(),
        tabs = subGroups:Select(
            function(value)
                local recipeLines = GetSubGroupPanelContent(value, inCount, outCount)
                return (GetSubGroupTabPanel(value, recipeLines))
            end
        ),
    }

end

local function GetGroupTabPanel(value, content)
    local group = value[1].Group
    return {
        tab = {
            type = "tab",
            name = "GetGroupTabPanel " .. GetNextId(),
            caption = "[item-group=" .. group.name .. "]",
            tooltip = group.localised_name,
            style = "ingteb-medium-tab",
        },
        content = content,
    }
end

function Class:GetCraftigGroupData(target, inCount, outCount)
    if target:Count() < settings.get_player_settings(self.Player)["ingteb_group-tab-threshold"]
        .value then
        return {
            type = "flow",
            direction = "vertical",
            name = "GetCraftigGroupData " .. GetNextId(),
            children = target:Select(
                function(recipe) return (GetRecipeLine(recipe, inCount, outCount)) end
            ),
        }
    end

    local groups =
        target:ToGroup(function(value) return {Key = value.Group.name, Value = value} end):ToArray()

    if groups:Count() == 1 then return self:GetGroupPanelContent(groups[1], inCount, outCount) end

    return {
        type = "tabbed-pane",
        tabs = groups:Select(
            function(value)
                local content = self:GetGroupPanelContent(value, inCount, outCount)
                return GetGroupTabPanel(value, content)
            end
        ),
    }

end

function Class:GetCraftingGroupPanel(target, category, inCount, outCount)
    dassert(type(category) == "string")
    inCount = math.min(inCount, maximalCount)
    outCount = math.min(outCount, maximalCount)

    local workers = target[1].Database:GetCategory(category).Workers

    local result = {
        type = "flow",
        name = "GetCraftingGroupPanel " .. GetNextId(),
        direction = "vertical",
        children = {
            GetWorkersPanel(workers, inCount + outCount + 3),
            {type = "line", direction = "horizontal"},
            self:GetCraftigGroupData(target, inCount, outCount),
            {type = "line", direction = "horizontal"},
        },
    }
    return result
end

function Class:GetCraftingGroupsPanel(target, headerSprites, tooltip)
    if not target or not target:Any() then return {} end
    local sampleCategogy = target:Top()
    dassert(type(sampleCategogy.Key) == "string")
    local sampleClient = sampleCategogy.Value[1]
    dassert(
        sampleClient.class == Recipe --
        or sampleClient.class == MiningRecipe --
        or sampleClient.class == Technology --
    )

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

    return {
        GetContentPanel(
            headerSprites, tooltip, target:Select(
                function(recipes, category)
                    dassert(type(category) == "string")
                    return self:GetCraftingGroupPanel(recipes, category, inCount, outCount)
                end
            ) --
            :ToArray()
        ),
    }
end

local function GetRecipePanel(target)
    if target.class.name ~= "Recipe" then return {} end
    local inCount = math.min(target.Input:Count(), maximalCount)
    local outCount = math.min(target.Output:Count(), maximalCount)
    local workers = target.Category.Workers
    return GetContentPanel(
        {"", target.RichTextName}, "Information about the recipe", {
            GetWorkersPanel(workers, inCount + outCount + 3),
            {type = "line", direction = "horizontal"},
            GetRecipeLine(target, inCount, outCount),
        }
    )
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

local function GetTechnologyList(target)
    local ingredientsCount = target --
    :Select(function(value) return value.Ingredients:Count() end):Maximum()

    local result = target:ToGroup(
        function(value)
            local key = value.Ingredients --
            :Select(function(stack) return stack.CommonKey end) --
            :Stringify(",")
            return {Key = key, Value = value}
        end
    ) --
    :ToArray():Select(
        function(values)
            local frame = {
                type = "flow",
                name = "GetTechnologyList " .. GetNextId(),
                direction = "horizontal",
                children = Spritor:GetTiles(ingredientsCount - values[1].Ingredients:Count()) --
                :Concat(
                    values[1].Ingredients:Select(
                        function(stack)
                            return Spritor:GetSpriteButtonAndRegister(stack)
                        end
                    )
                ) --
                :Concat{
                    {type = "label", caption = "[img=utility/go_to_arrow]"},
                    {
                        type = "table",
                        column_count = 2,
                        children = values:Select(
                            function(target)
                                return {
                                    type = "frame",
                                    direction = "horizontal",
                                    children = {
                                        Spritor:GetSpriteButtonAndRegister(target),
                                        Spritor:GetSpriteButton{
                                            SpriteName = "item/lab",
                                            NumberOnSprite = target.Amount,
                                        },
                                        Spritor:GetSpriteButton{
                                            SpriteName = "utility/clock",
                                            NumberOnSprite = target.Time,
                                        },
                                    },
                                }
                            end
                        ),
                    },
                },
            }
            return frame
        end
    )
    return result
end

local function GetTechnologiesExtendedPanel(target, headerSprites, isPrerequisites, tooltip)
    if not target or not target:Any() then return {} end
    dassert(target:Top().class == Technology)

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

    return {
        GetContentPanel(
            headerSprites, tooltip, Array:new{
                GetTechnologyList(target),
                {{type = "line", direction = "horizontal"}},
                GetTechnologyList(targetExtendend),
            }:ConcatMany()
        ),
    }

end

local function GetTechnologiesPanel(target, headerSprites, tooltip)
    if not target or not target:Any() then return {} end
    dassert(target:Top().class == Technology)

    return {
        GetContentPanel(headerSprites, tooltip, Array:new{GetTechnologyList(target)}:ConcatMany()),
    }

end

function Class:CheckedTabifyColumns(frame, mainFrame, target, columnCount)
    local maximalColumCount =
        settings.get_player_settings(self.Player)["ingteb_column-tab-threshold"].value
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

function Class:Close()
    if self.Current then
        self.Current.destroy()
        self.Current = nil
        Spritor:Close()
        self.Global.Links.Presentator = {}
    end
end

function Class:OnMainInventoryChanged(event) Spritor:RefreshMainInventoryChanged() end

function Class:OnStackChanged() end

function Class:OnResearchChanged(event) Spritor:RefreshResearchChanged() end

function Class:Open(target)
    log("opening Target = " .. target.CommonKey .. "...")
    self.Global.Links.Presentator = {}
    Spritor:StartCollecting()
    local guiData = self:GetGui(target)
    -- log("guiData= " .. serpent.block(guiData))
    if target.class == Entity and target.Item then target = target.Item end
    local result = Helper.CreateFloatingFrameWithContent(self, guiData, target.LocalisedName)
    Spritor:RegisterDynamicTargets(result.DynamicElements)
    self.Current = result.Main
    log("opening Target = " .. target.CommonKey .. " ok.")
end

function Class:GetGui(target)
    target:SortAll()
    dassert(
        not target.RecipeList or not next(target.RecipeList) or type(next(target.RecipeList))
            == "string"
    )
    dassert(not target.UsedBy or not next(target.UsedBy) or type(next(target.UsedBy)) == "string")
    dassert(

        not target.CreatedBy or not next(target.CreatedBy) or type(next(target.CreatedBy))
            == "string"
    )

    local columnCount --
    = (target.RecipeList and target.RecipeList:Any() and 1 or 0) --
          + (target.class == Recipe and 1 or 0) --
          + (target.Prerequisites and target.Prerequisites:Any() and 1 or 0) --
          + (target.Effects and target.Effects:Any() and 1 or 0) --
          + (target.Enables and target.Enables:Any() and 1 or 0) --
          + (target.UsedBy and target.UsedBy:Any() and 1 or 0) --
          + (target.CreatedBy and target.CreatedBy:Any() and 1 or 0) --
          + (target.ResearchingTechnologies and target.ResearchingTechnologies:Any() and 1 or 0) --

    local children
    if columnCount == 0 then
        children = {
            type = "frame",
            direction = "horizontal",
            children = {
                {
                    type = "label",
                    caption = "[img=utility/crafting_machine_recipe_not_unlocked][img=utility/go_to_arrow]",
                },
                Spritor:GetSpriteButtonAndRegister(target),
                {
                    type = "label",
                    caption = "[img=utility/go_to_arrow][img=utility/crafting_machine_recipe_not_unlocked]",
                },
            },
        }
    else
        children = {
            {
                type = "scroll-pane",
                horizontal_scroll_policy = "never",
                direction = "vertical",
                name = "frame",
                children = {
                    {
                        type = columnCount > 1 and "frame" or "flow",
                        direction = "horizontal",
                        name = "frame",
                        children = Array:new{
                            GetTechnologiesPanel(
                                target.ResearchingTechnologies,
                                    target.RichTextName
                                        .. "[img=utility/go_to_arrow][img=entity/lab]",
                                    {"ingteb-utility.researching-technologies-for-item"}
                            ),
                            GetTechnologiesExtendedPanel(
                                target.Prerequisites,
                                    "[img=utility/missing_icon][img=utility/go_to_arrow]"
                                        .. target.RichTextName, true,
                                    {"ingteb-utility.prerequisites-for-technology"}

                            ),
                            GetTechnologyEffectsPanel(target),
                            GetRecipePanel(target),
                            GetTechnologiesExtendedPanel(
                                target.Enables, target.RichTextName
                                    .. "[img=utility/go_to_arrow][img=utility/missing_icon]", false,
                                    {"ingteb-utility.technologies-enabled"}

                            ),
                            self:GetCraftingGroupsPanel(
                                target.RecipeList,
                                    target.RichTextName .. "[img=utility/change_recipe]",
                                    {"ingteb-utility.recipes-for-worker"}
                            ),
                            self:GetCraftingGroupsPanel(
                                target.CreatedBy,
                                    "[img=utility/missing_icon][img=utility/go_to_arrow]"
                                        .. target.RichTextName,
                                    {"ingteb-utility.creating-recipes-for-item"}

                            ),
                            self:GetCraftingGroupsPanel(
                                target.UsedBy, target.RichTextName
                                    .. "[img=utility/go_to_arrow][img=utility/missing_icon]",
                                    {"ingteb-utility.consuming-recipes-for-item"}
                            ),
                        }:ConcatMany(),

                    },
                },

            },
        }
    end

    return {type = "flow", direction = "vertical", children = children}
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    if message.action == "Closed" then
        if self.Global.IsPopup then
            self.Current.ignored_by_interaction = true
        else
            self:Close()
        end
    elseif message.subModule == "Spritor" then
        Spritor:OnGuiEvent(event)
    else
        dassert()
    end
end

function Class:OnSettingsChanged(event)
    -- dassert()   
end

function Class:RestoreFromSave(parent)
    self.Parent = parent
    local current = self.Player.gui.screen[self.class.name]
    if current then
        current.destroy()
        self:Open(self.Database:GetProxyFromCommonKey(self.Global.History.Current))
    end
end

return Class
