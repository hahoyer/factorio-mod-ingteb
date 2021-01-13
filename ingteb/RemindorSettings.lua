local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local RemindorTask = require "ingteb.remindortask"
local Array = Table.Array
local Dictionary = Table.Dictionary

local Class = {}

local function GetGui(self)
    return {
        type = "flow",
        direction = "vertical",
        name = self.CommonKey,
        children = {
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {
                        type = "checkbox",
                        caption = {"ingteb-utility.default"},
                        state = self.Settings.AutoResearch == nil,
                        actions = {
                            on_checked_state_changed = {
                                module = "Remindor",
                                target = self.class.name,
                                action = "UpdateOverride",
                                control = "AutoResearch",
                                key = self.CommonKey,
                            },
                        },
                    },
                    {
                        type = "checkbox",
                        caption = {"ingteb-utility.auto-research"},
                        state = self.AutoResearch,
                        ignored_by_interaction = self.Settings.AutoResearch == nil,
                        actions = {
                            on_checked_state_changed = {
                                module = "Remindor",
                                target = self.class.name,
                                action = "Update",
                                control = "AutoResearch",
                                key = self.CommonKey,
                            },
                        },
                    },
                },
            },
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {
                        type = "checkbox",
                        caption = {"ingteb-utility.default"},
                        state = self.Settings.AutoCrafting == nil,
                        actions = {
                            on_checked_state_changed = {
                                module = "Remindor",
                                target = self.class.name,
                                action = "UpdateOverride",
                                control = "AutoCrafting",
                                key = self.CommonKey,
                            },
                        },
                    },
                    {
                        type = "drop-down",
                        items = {
                            {"ingteb-utility.auto-crafting-off"},
                            {"ingteb-utility.auto-crafting-1"},
                            {"ingteb-utility.auto-crafting-5"},
                            {"ingteb-utility.auto-crafting-all"},
                        },
                        selected_index = self.AutoCrafting,
                        caption = {"ingteb-utility.auto-crafting"},
                        ignored_by_interaction = self.Settings.AutoCrafting == nil,
                        actions = {
                            on_selection_state_changed = {
                                module = "Remindor",
                                target = self.class.name,
                                action = "Update",
                                control = "AutoCrafting",
                                key = self.CommonKey,
                            },
                        },
                    },
                },
            },
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {
                        type = "checkbox",
                        caption = {"ingteb-utility.default"},
                        state = self.Settings.RemoveTaskWhenFulfilled == nil,
                        actions = {
                            on_checked_state_changed = {
                                module = "Remindor",
                                target = self.class.name,
                                action = "UpdateOverride",
                                control = "RemoveTaskWhenFulfilled",
                                key = self.CommonKey,
                            },
                        },
                    },
                    {
                        type = "checkbox",
                        caption = {"ingteb-utility.remove-when-fulfilled"},
                        state = self.RemoveTaskWhenFulfilled,
                        ignored_by_interaction = self.Settings.RemoveTaskWhenFulfilled == nil,
                        actions = {
                            on_checked_state_changed = {
                                module = "Remindor",
                                target = self.class.name,
                                action = "Update",
                                control = "RemoveTaskWhenFulfilled",
                                key = self.CommonKey,
                            },
                        },
                    },
                },
            },
        },
    }
end

function Class.Open(remindor, self)
    if not self.Global.Location.RemindorSettings then
        self.Global.Location.RemindorSettings = {x = 200, y = 100}
    end
    local caption = {"ingteb-utility.reminder-tasks-settings"}
    if self.class.name  == "Task" then 
        caption = {"", caption, self.Target.RichTextName,self.Worker.RichTextName,self.Recipe.RichTextName}
    end
    local result = Helper.CreatePopupFrameWithContent(
        remindor, GetGui(self), caption, {subModule = "Settings"}
    )
    return result.Main
end

return Class
