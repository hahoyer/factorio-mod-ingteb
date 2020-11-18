local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local ValueCache = require("core.ValueCache")
require("ingteb.Common")

function Technology(name, prototype, database)
    local self = Common(name, prototype, database)
    self.class_name = "Technology"
    self.SpriteType = "technology"

    function self:Setup()
        self.Prerequisites = Array:new(self.Prototype.prerequisites) --
        :Select(function(technology) return assert() end)

        self.In = Array:new(self.Prototype.research_unit_ingredients) --
        :Select(
            function(tag)
                local result = database:GetItemSet(tag)
                result.Item.TechnologyIngredients:Append(self)
                return result
            end
        )

        self.Out = Array:new(self.Prototype.effects) --
        :Select(
            function(effect)
                if effect.type == "unlock-recipe" then
                    local result = database.Recipes[effect.recipe]
                    result.Technologies:Append(self)
                    return result
                else
                    database:AddBonus(effect, self)
                    return
                end
            end
        ) --
        :Where(function(item) return item end)
    end

    return self
end

