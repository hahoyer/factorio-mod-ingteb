local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local ValueCache = require("core.ValueCache")
local PropertyProvider = require("core.PropertyProvider")

function Common(name, prototype, database)
    local self = PropertyProvider:new{
        Name = name,
        Prototype = prototype,
        Database = database,
        cache = {},
    }

    function self:addCachedProperty(name, getter)
        self.cache[name] = ValueCache(getter)
        self.property[name] = {get = function(self) return self.cache[name].Value end}
    end

    self:addCachedProperty(
        "SpriteName", function() return self.SpriteType .. "/" .. self.Prototype.name end
    )
    self.LocalisedName = self.Prototype.localised_name
    self.property.FunctionHelp = {get = function() return end}
    self.LocalizedDescription = self.Prototype.localised_description

    self.property.HasLocalisedDescription = {
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
    }

    self.property.HelperText = {
        get = function()
            local name = self.Prototype.localised_name
            local description = self.LocalizedDescription
            local help = self.FunctionHelp

            local result = name
            if self.HasLocalisedDescription then
                result = {"ingteb_utility.Lines2", result, description}
            end
            if help then result = {"ingteb_utility.Lines2", result, help} end
            return result
        end,
    }

    return self
end
