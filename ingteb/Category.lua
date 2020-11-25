local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local Common = require("ingteb.Common")

function OldCategory(domainName, prototype, database)
    local self = Common(prototype.name, prototype, database)
    self.object_name = "Category"
    self.DomainName = domainName
    self.Workers = Array:new()
    self.Recipes = Array:new()

    function self:Setup() end

    return self
end

local Category = Common:class("Category")

local function GetPrototype(name)
    local _, _, domain, category = name:find("^(.+)%.(.+)$")
    if domain == "crafting" then
        return game.recipe_category_prototypes[category]
    elseif domain == "mining" then
        return game.resource_category_prototypes[category]
    else
        assert()
    end
end

function Category:new(name, prototype, database)
    local self = Common:new(prototype or GetPrototype(name), database)
    self.object_name = Category.object_name

    assert(
        self.Prototype.object_name == "LuaResourceCategoryPrototype" --
        or self.Prototype.object_name == "LuaRecipeCategoryPrototype"
    )

    self.Workers = Array:new()
    self.Recipes = Array:new()

    self:properties{}

    return self

end

return Category

