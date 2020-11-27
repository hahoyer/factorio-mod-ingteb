local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local ValueCacheContainer = require("core.ValueCacheContainer")

local Common = {object_name = "Common"}

function Common:class(name) return {object_name = name} end

function Common:new(prototype, database)
    assert(prototype)
    assert(database)

    local self = ValueCacheContainer:new{Prototype = prototype, Database = database}
    function self:properties(list)
        for key, value in pairs(list) do
            if value.cache then
                self:addCachedProperty(key, value.get)
            else
                self.property[key] = {get = value.get, set = value.set}
            end

        end
    end

    self.object_name = Common.object_name
    self.Name = self.Prototype.name
    self.LocalizedDescription = self.Prototype.localised_description

    self:properties{
        LocalisedName = {
            get = function()
                return {
                    "gui-text-tags.following-text-" .. (self.TypeForLocalisation or self.SpriteType),
                    self.Prototype.localised_name,
                }
            end,
        },

        FunctionHelp = {get = function() return end},

        HasLocalisedDescription = {
            get = function()
                if self.HasLocalisedDescriptionPending ~= nil then
                    return not self.HasLocalisedDescriptionPending
                end

                local key = self.LocalizedDescription[1]

                if key then
                    if key == "modifier-description.train-braking-force-bonus" then
                        local x = 2
                    end
                    local start = not global.Current.PendingTranslation:Any()
                    global.Current.PendingTranslation[key] = self
                    self.HasLocalisedDescriptionPending = true
                    if start then Helper.InitiateTranslation() end
                end
                return nil

            end,
        },

        HelperText = {
            get = function()
                local name = self.Prototype.localised_name
                local description = self.LocalizedDescription
                local help = self.FunctionHelp

                local result = name
                if false and self.HasLocalisedDescription then
                    result = {"ingteb_utility.Lines2", result, description}
                end
                if help then result = {"ingteb_utility.Lines2", result, help} end
                return result
            end,
        },
        SpriteName = {
            chache = true,
            get = function() return self.SpriteType .. "/" .. self.Prototype.name end,
        },
    }
    return self

end

return Common
