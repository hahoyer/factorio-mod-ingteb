local localisation = require "__flib__.dictionary"
local migration = require "__flib__.migration"
local Constants = require "Constants"
local Helper = require "ingteb.Helper"

local Array = require "core.Array"
local Dictionary = require "core.Dictionary"
local class = require("core.class")

local Class = class:new("LocalisationInformation", nil, {})

function Class:new(parent) return self:adopt { Parent = parent } end

function Class:CreateDictionaries()
    local names = localisation.new("Names")
    local descriptions = localisation.new("Descriptions")
    log("localisation initialize ...")

    for _, type in pairs { "entity", "fluid", "item", "recipe", "recipe_category", "technology", "fuel_category", "resource_category" } do
        local key = type .. "_prototypes"
        for name, prototype in pairs(game[key]) do
            names:add(key .. "." .. name, prototype.localised_name)
            descriptions:add(key .. "." .. name, prototype.localised_description)
        end
    end
end

function Class:OnInitialise()
    localisation.init()
    global.Localisation = {}
    self:CreateDictionaries()
end

function Class:OnLoad()
    localisation.load()
end

function Class:OnConfigurationChanged(event)
    if migration.on_config_changed(event, {}) then
        localisation.init()
        self:CreateDictionaries()

        for _, player in pairs(game.players) do
            if player.connected then
                localisation.translate(player)
            end
        end
    end
end

function Class:OnPlayerCreated(event)
    local player = game.get_player(event.player_index)
    if player.connected then
        localisation.translate(player)
    end
end

function Class:OnPlayerJoined(event)
    local player = game.get_player(event.player_index)
    localisation.translate(player)
end

function Class:OnPlayerLeft(event)
    localisation.cancel_translation(event.player_index)
end

function Class:OnTranslationBatch(event) localisation.check_skipped(event) end

function Class:OnStringTranslated(event)
    local language_data = localisation.process_translation(event)
    local result = Array:new()
    if language_data then
        result = Array:new(language_data.players)
            :Select(function(index)
                global.Players[index].Localisation = language_data.dictionaries
                return index
            end)
    end
    log("localisation initialize complete.")
    return result
end

return Class
