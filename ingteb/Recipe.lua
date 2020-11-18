local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local ValueCache = require("core.ValueCache")
require("ingteb.Common")

function Recipe(name, prototype, database)
    local self = Common(name, prototype, database)
    self.class_name = "Recipe"
    self.SpriteType = "recipe"
    self.Technologies = Array:new()

    self:addCachedProperty(
        "Technology", function()
            assert(self.Technologies:Count() <= 1)
            return self.Technologies:Top()
        end
    )

    function self:Setup()
        local category = self.Prototype.category .. " crafting"
        self.In = Array:new(self.Prototype.ingredients) --
        :Select(
            function(ingredient)
                local result = database:GetItemSet(ingredient)
                self:AppendForKey(category, result.Item.In)
                return result
            end
        )

        self.Out = Array:new(self.Prototype.products) --
        :Select(
            function(product)
                local result = database:GetItemSet(product)
                self:AppendForKey(category, result.Item.Out)
                return result
            end
        )

        self.WorkingEntities --
        = database.WorkingEntities[category]
        self.WorkingEntities --
        :Select(function(entity) entity.CraftingRecipes:Append(self) end)

    end

    return self
end

