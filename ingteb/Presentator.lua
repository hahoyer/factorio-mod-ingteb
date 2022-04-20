local Constants = require("Constants")
local gui = require("__flib__.gui-beta")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local class = require("core.class")
local Recipe = require("ingteb.Recipe")
local Technology = require("ingteb.Technology")
local Bonus = require("ingteb.Bonus")
local Entity = require("ingteb.Entity")
local RecipeCommon = require "ingteb.RecipeCommon"
local BurningRecipe = require "ingteb.BurningRecipe"
local Spritor = require "ingteb.Spritor"

local Class = class:new(
    "Presentator", nil, {
        Player = {get = function(self) return self.Parent.Player end},
        Global = {get = function(self) return self.Parent.Global end},
        Database = {get = function(self) return self.Parent.Database end},
        ChangeWatcher = {get = function(self) return self.Parent.Modules.ChangeWatcher end},
        MainGui = {
            get = function(self)
                return self.Player.gui.screen[Constants.ModName .. "." .. self.class.name]
            end,
        },
    }
)

function Class:new(parent)
    local self = self:adopt{Parent = parent}
    self.Spritor = Spritor:new(self)
    return self
end

function Class:GetNextId()
    self.NextId = self.NextId + 1
    return self.NextId
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

local maximalCount = Constants.MaximumEntriesInRecipeList

function Class:GetRespondingSpriteButton(target, sprite, category)
    return self.Spritor:GetRespondingSpriteButton(target, sprite, category)
end

function Class:GetSpriteButton(target, sprite, category)
    return self.Spritor:GetSpriteButton(target, sprite, category)
end

function Class:GetLinePart(target, maximumCount, isRightAligned, tooltip)
    return self.Spritor:GetLinePart(target, maximumCount, isRightAligned, tooltip)
end

function Class:GetTechnologyButton(target)
    if target.IsHidden then
        return {
            type = "sprite-button",
            sprite = "automatic-recipe",
            tooltip = {"ingteb-utility.automatic-recipe"},
        }
    elseif target.Technology then
        return self:GetRespondingSpriteButton(target.Technology)
    elseif target.Prototype.enabled then
        return {
            type = "sprite-button",
            sprite = "factorio",
            tooltip = {"ingteb-utility.initial-technology"},
        }
    else
        return {
            type = "sprite-button",
            sprite = "utility/crafting_machine_recipe_not_unlocked",
            tooltip = {"ingteb-utility.impossible-recipe"},
        }
    end
end

function Class:GetRecipeLine(target, inCount, outCount)
    return {
        type = "flow",
        name = "GetRecipeLine " .. self:GetNextId(),
        direction = "horizontal",
        children = {
            self:GetLinePart(target.Input, inCount, true),
            {
                type = "flow",
                name = "GetRecipeLine inner " .. self:GetNextId(),
                direction = "horizontal",
                children = {
                    {type = "sprite", sprite = "go_to_arrow"},
                    self:GetTechnologyButton(target),
                    self:GetRespondingSpriteButton(target),
                    self:GetRespondingSpriteButton(
                        {SpriteName = "utility/clock", NumberOnSprite = target.Time}
                    ),
                    {type = "sprite", sprite = "go_to_arrow"},
                },
            },
            self:GetLinePart(target.Output, outCount, false),
        },
    }

end

function Class:GetWorkersPanel(category, columnCount)
    local workers = category.Workers
    if not workers:Any() then
        workers = Array:new{
            {
                SpriteName = "utility/crafting_machine_recipe_not_unlocked",
                HelperText = {"ingteb-utility.no-worker-for-recipe"},
            },
        }
    end
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
                    sprite = category.LineSprite,
                    tooltip = category:GetHelperText("Presentator"),
                    actions = {
                        on_click = {
                            module = self.class.name,
                            action = "Click",
                            key = category.CommonKey,
                        },
                    },
                }
            end
            if lines == 1 and position == 0 then
                workersPanelData:AppendMany(self.Spritor:GetTiles(dummyColumnsLeft))
                position = position + dummyColumnsLeft
            end

            workersPanelData:Append(self:GetRespondingSpriteButton(worker, nil, category))

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

function Class:GetTechnologyEffectsData(target)
    local effects = target.Effects

    if not effects:Any() then
        return {
            type = "flow",
            name = "GetTechnologyEffectsData no effects " .. self:GetNextId(),
            direction = "horizontal",
            {
                type = "label",
                caption = "[img=go_to_arrow][img=utility/crafting_machine_recipe_not_unlocked]",
            },
        }

    end

    dassert(effects[1].class == Recipe or effects[1].class == Bonus)

    local inCount = effects --
    :Select(function(recipe) return recipe.Input and recipe.Input:Count() or 0 end) --
    :Maximum()
    local outCount = effects --
    :Select(function(recipe) return recipe.Output and recipe.Output:Count() or 0 end) --
    :Maximum()

    return {
        type = "flow",
        name = "GetTechnologyEffectsData " .. self:GetNextId(),
        direction = "vertical",
        children = effects:Select(
            function(effekt)
                if effekt.class == Recipe then
                    return self:GetRecipeLine(effekt, inCount, outCount)
                else
                    return {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            self:GetRespondingSpriteButton(target),
                            {type = "label", caption = "[img=go_to_arrow]"},
                            self:GetRespondingSpriteButton(effekt),
                        },
                    }
                end
            end
        ),
    }

end

function Class:GetTechnologyEffectsPanel(target)
    if not target or not target.Effects then return {} end

    return {
        GetContentPanel(
            target.RichTextName .. "[img=effects]", --
            {"gui-technology-preview.effects"}, --
            {
                {
                    type = "flow",
                    name = "GetTechnologyEffectsPanel " .. self:GetNextId(),
                    direction = "horizontal",
                    children = {
                        {
                            type = "sprite",
                            sprite = "utility/change_recipe",
                            tooltip = {"ingteb-utility.technology-research-ingredients"},
                        },
                        {
                            type = "flow",
                            name = "GetTechnologyEffectsPanel inner " .. self:GetNextId(),
                            direction = "horizontal",
                            style = "ingteb-flow-centered",
                            children = target.Ingredients:Select(
                                function(stack)
                                    return self:GetSpriteButton(
                                        stack.Goods:CreateStack{
                                            value = stack.Amounts.value
                                                * target.Prototype.research_unit_count,
                                        }
                                    )
                                end
                            ):Concat{
                                self:GetSpriteButton{
                                    SpriteName = "utility/clock",
                                    NumberOnSprite = target.Time,
                                },
                            },
                        },
                    },
                },
                {type = "line", direction = "horizontal"},
                self:GetTechnologyEffectsData(target),
            }
        ),
    }

end

function Class:GetSubGroupTabPanel(subGroup, recipeLines)
    local group = subGroup[1].SubGroup
    local caption = group.name
    if subGroup and subGroup[1].Output[1] then
        local main = subGroup[1].Output[1]
        caption = main.RichTextName
    end
    return {
        tab = {
            type = "tab",
            name = "GetSubGroupTabPanel " .. self:GetNextId(),
            caption = caption,
            tooltip = group.localised_name,
            style = "ingteb-medium-tab",
        },
        content = recipeLines,
    }
end

function Class:GetSubGroupPanelContent(target, inCount, outCount)
    return {
        type = "flow",
        direction = "vertical",
        name = "GetSubGroupPanelContent " .. self:GetNextId(),
        children = target:Select(
            function(recipe) return self:GetRecipeLine(recipe, inCount, outCount) end
        ),
    }
end

function Class:GetGroupPanelContent(value, inCount, outCount)
    if value:Count()
        < settings.get_player_settings(self.Player)["ingteb_subgroup-tab-threshold"].value then
        return {
            type = "flow",
            direction = "vertical",
            name = "GetGroupPanelContent " .. self:GetNextId(),
            children = value:Select(
                function(recipe) return self:GetRecipeLine(recipe, inCount, outCount) end
            ),
        }
    end

    local subGroups = value:ToGroup(
        function(value) return {Key = value.SubGroup.name, Value = value} end
    ):ToArray() --

    if subGroups:Count() == 1 then
        return self:GetSubGroupPanelContent(subGroups[1], inCount, outCount)
    end

    return {
        type = "tabbed-pane",
        name = "GetGroupPanelContent " .. self:GetNextId(),
        tabs = subGroups:Select(
            function(value)
                local recipeLines = self:GetSubGroupPanelContent(value, inCount, outCount)
                return (self:GetSubGroupTabPanel(value, recipeLines))
            end
        ),
    }

end

function Class:GetGroupTabPanel(value, content)
    local group = value[1].Group
    return {
        tab = {
            type = "tab",
            name = "GetGroupTabPanel " .. self:GetNextId(),
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
            name = "GetCraftigGroupData " .. self:GetNextId(),
            children = target:Select(
                function(recipe)
                    return (self:GetRecipeLine(recipe, inCount, outCount))
                end
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
                return self:GetGroupTabPanel(value, content)
            end
        ),
    }

end

function Class:GetCraftingGroupPanel(target, category, inCount, outCount)
    dassert(type(category) == "string")
    inCount = math.min(inCount, maximalCount)
    outCount = math.min(outCount, maximalCount)

    local result = {
        type = "flow",
        name = "GetCraftingGroupPanel " .. self:GetNextId(),
        direction = "vertical",
        children = {
            self:GetWorkersPanel(self.Database:GetCategory(category), inCount + outCount + 3),
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
        or sampleClient.class == RecipeCommon --
        or sampleClient.class == BurningRecipe --
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

function Class:GetFuelsPanel(target, headerSprites, tooltip)
    if not target or not target:Any() then return {} end

    return {
        GetContentPanel(
            headerSprites, tooltip, {self:GetLinePart(target, target:Count(), true)} --
        ),
    }
end

function Class:GetUsefulLinksPanel(target)
    if not target or not target:Any() then return {} end
    local children = target --
    :Select(
        function(group)
            return self:GetLinePart(group, nil, nil, {"ingteb-utility.properties"})
        end
    )
    if #children == 1 then return children end
    return {
        {
            type = "flow",
            name = "GetUsefulLinksPanel " .. self:GetNextId(),
            direction = "vertical",
            children = children,
        },
    }
end

function Class:GetRecipePanel(target)
    if not target.IsRecipe then return {} end
    local inCount = math.min(target.Input:Count(), maximalCount)
    local outCount = math.min(target.Output:Count(), maximalCount)
    return {
        GetContentPanel(
            {"", target.RichTextName}, {"ingteb-utility.recipe-information"}, {
                self:GetWorkersPanel(target.Category, inCount + outCount + 3),
                {type = "line", direction = "horizontal"},
                self:GetRecipeLine(target, inCount, outCount),
            }
        ),
    }
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

function Class:GetTechnologyList(target)
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
                name = "GetTechnologyList " .. self:GetNextId(),
                direction = "horizontal",
                children = self.Spritor:GetTiles(ingredientsCount - values[1].Ingredients:Count()) --
                :Concat(
                    values[1].Ingredients:Select(
                        function(stack)
                            return self:GetRespondingSpriteButton(stack)
                        end
                    )
                ) --
                :Concat{
                    {type = "label", caption = "[img=go_to_arrow]"},
                    {
                        type = "table",
                        column_count = 2,
                        children = values:Select(
                            function(target)
                                return {
                                    type = "frame",
                                    direction = "horizontal",
                                    children = {
                                        self:GetRespondingSpriteButton(target),
                                        self:GetSpriteButton{
                                            SpriteName = "item/lab",
                                            NumberOnSprite = target.Amount,
                                        },
                                        self:GetSpriteButton{
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

function Class:GetTechnologiesExtendedPanel(target, headerSprites, isPrerequisites, tooltip)
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
                self:GetTechnologyList(target),
                {{type = "line", direction = "horizontal"}},
                self:GetTechnologyList(targetExtendend),
            }:ConcatMany()
        ),
    }

end

function Class:GetTechnologiesPanel(target, headerSprites, tooltip)
    if not target or not target:Any() then return {} end
    dassert(target:Top().class == Technology)

    return {
        GetContentPanel(
            headerSprites, tooltip, Array:new{self:GetTechnologyList(target)}:ConcatMany()
        ),
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
    if self.MainGui then
        self.MainGui.destroy()
        self.Spritor:Close()
        self.Global.Links.Presentator = {}
    end
end

function Class:Open(target)
    log("opening Target = " .. target.CommonKey .. "...")
    self.Global.Links.Presentator = {}
    self.Spritor:StartCollecting()
    local guiData = self:GetGui(target)
    -- log("guiData= " .. serpent.block(guiData))
    if target.class == Entity and target.Item then target = target.Item end
    local result = Helper.CreateFloatingFrameWithContent(self, guiData, target.LocalisedName)
    self.Spritor:RegisterDynamicElements(result.DynamicElements)
    log("opening Target = " .. target.CommonKey .. " ok.")
end

local function PlaceUsefulLinks(targets)
    if #targets.CreatedBy > 0 then
        targets.CreatedBy[1] = {
            type = "flow",
            direction = "vertical",
            name = "properties&createdBy",
            children = {targets.CreatedBy[1], targets.UsefulLinks[1]},
        }
        targets.UsefulLinks = {}
    end
end

local function CreateMainPanel(rawTargets)
    local targets = Dictionary.Clone(rawTargets)
    if #rawTargets.UsefulLinks > 0 then PlaceUsefulLinks(targets) end
    local lists = targets:ToArray()
    dassert(lists:All(function(item) return #item < 2 end))
    return lists:ConcatMany()
end

function Class:GetGui(target)
    self.NextId = 0
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
    + (target.IsRecipe and 1 or 0) --
    + (target.Prerequisites and target.Prerequisites:Any() and 1 or 0) --
          + (target.Effects and target.Effects:Any() and 1 or 0) --
          + (target.Enables and target.Enables:Any() and 1 or 0) --
          + (target.UsedBy and target.UsedBy:Any() and 1 or 0) --
          + (target.CreatedBy and target.CreatedBy:Any() and 1 or 0) --
          + (target.ResearchingTechnologies and target.ResearchingTechnologies:Any() and 1 or 0) --
          + (target.UsefulLinks and target.UsefulLinks:Any() and 1 or 0) --

    local children
    if columnCount == 0 then
        children = {
            {
                type = "frame",
                direction = "horizontal",
                children = {
                    {
                        type = "label",
                        caption = "[img=utility/crafting_machine_recipe_not_unlocked][img=go_to_arrow]",
                    },
                    self:GetRespondingSpriteButton(target),
                    {
                        type = "label",
                        caption = "[img=go_to_arrow][img=utility/crafting_machine_recipe_not_unlocked]",
                    },
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
                        children = CreateMainPanel {
                            ResearchingTechnologies = self:GetTechnologiesPanel(
                                target.ResearchingTechnologies,
                                    target.RichTextName .. "[img=go_to_arrow][img=entity/lab]",
                                    {"ingteb-utility.researching-technologies-for-item"}
                            ),
                            Prerequisites = self:GetTechnologiesExtendedPanel(
                                target.Prerequisites, "[img=utility/missing_icon][img=go_to_arrow]"
                                    .. target.RichTextName, true,
                                    {"ingteb-utility.prerequisites-for-technology"}

                            ),
                            TechnologyEffectsPanel = self:GetTechnologyEffectsPanel(target),
                            RecipePanel = self:GetRecipePanel(target),
                            TechnologiesExtendedPanel = self:GetTechnologiesExtendedPanel(
                                target.Enables, target.RichTextName
                                    .. "[img=go_to_arrow][img=utility/missing_icon]", false,
                                    {"ingteb-utility.technologies-enabled"}

                            ),
                            RecipeList = self:GetCraftingGroupsPanel(
                                target.RecipeList,
                                    target.RichTextName .. "[img=utility/change_recipe]",
                                    {"ingteb-utility.recipes-for-worker"}
                            ),
                            UsefulLinks = self:GetUsefulLinksPanel(target.UsefulLinks),
                            CreatedBy = self:GetCraftingGroupsPanel(
                                target.CreatedBy, "[img=utility/missing_icon][img=go_to_arrow]"
                                    .. target.RichTextName,
                                    {"ingteb-utility.creating-recipes-for-item"}

                            ),
                            UsedBy = self:GetCraftingGroupsPanel(
                                target.UsedBy, target.RichTextName
                                    .. "[img=go_to_arrow][img=utility/missing_icon]",
                                    {"ingteb-utility.consuming-recipes-for-item"}
                            ),
                        },

                    },
                },

            },
        }
    end

    return {type = "flow", name = "Panels", direction = "vertical", children = children}
end

function Class:OnGuiEvent(event)
    local message = gui.read_action(event)
    if message.action == "Closed" then
        if self.Global.IsPopup then
            self.MainGui.ignored_by_interaction = true
        else
            self:Close()
        end
    elseif message.action == "Click" then
        self.Parent:OnGuiClick(event)
    else
        dassert()
    end
end

function Class:OnSettingsChanged(event) end

function Class:RestoreFromSave(parent)
    self.Parent = parent
    local current = self.Player.gui.screen[self.class.name]
    if current then
        current.destroy()
        self:Open(self.Database:GetProxyFromCommonKey(self.Global.History.Current))
    end
end

return Class
