local Constants = require("Constants")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
require("ingteb.Common")

function Recipe(name, prototype, database)
    local self = Common(name, prototype, database)
    self.class_name = "Recipe"
    self.SpriteType = "recipe"
    self.Technologies = Array:new()

    self.Time = self.Prototype.energy

    self.property.Technology = {
        get = function(self)
            if self.Technologies:Count() <= 1 then return self.Technologies:Top() end

            local researched = self.Technologies:Where(
                function(technology) return technology.IsResearched end
            )
            if researched:Count() > 0 then return researched:Top() end

            local ready = self.Technologies:Where(
                function(technology) return technology.IsReady end
            )
            if ready:Count() > 0 then return researched:Top() end

            return self.Technologies:Top()
        end,
    }

    self.property.IsResearched = {
        get = function(self)
            return --
            not self.Technologies:Any() --
                or self.Technologies:Any(
                    function(technology) return technology.IsResearched end
                )
        end,
    }

    self.property.NumberOnSprite = {
        get = function(self)
            if not self.HandCrafter then return end
            local result =  global.Current.Player.get_craftable_count(self.Name)
            if result > 0 then return result end
        end,
    }

    self.property.Order = {get = function(self) return self.IsResearched and 1 or 0 end}
    self.property.SubOrder = {
        get = function(self)
            return (not self.Technology or self.Technology.IsReady) and 1 or 0
        end,
    }

    function self:Setup()
        local category = self.Prototype.category .. " crafting"
        self.Category = self.Database.Categories[category]
        self.Category.Recipes:Append(self)

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
                self:AppendForKey(
                    category, result.Item.Out, function(entry, value)
                        entry:Append(value)
                    end
                )
                return result
            end
        )

        self.HandCrafter = self.Category.Workers:Where(
            function(worker) return worker.Name == "character" end
        ):Top()
    end

    return self
end

