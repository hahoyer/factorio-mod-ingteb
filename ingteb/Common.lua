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
    self.In = Dictionary:new{}
    self.Out = Dictionary:new{}

    function self:addCachedProperty(name, getter)
        self.cache[name] = ValueCache(getter)
        self.property[name] = {get = function(self) return self.cache[name].Value end}
    end

    self.LocalisedName = self.Prototype.localised_name
    self.HelperText = self.Prototype.localised_name

    self:addCachedProperty("SpriteName", function() return self.SpriteType .. "/" .. self.Name end)

    self:addCachedProperty(
        "Description", function()
            if self.Prototype and self.Prototype.localised_description then
                global.Current.PendingTranslation[self.Prototype.localised_description] = self
                global.Current.Player.request_translation(self.Prototype.localised_description)
            end
            return self.ActualDescription
        end
    )

    return self
end

function CommonThing(name, prototype, database)
    local self = Common(name, prototype, database)

    self.TechnologyIngredients = Array:new{}

    return self
end
