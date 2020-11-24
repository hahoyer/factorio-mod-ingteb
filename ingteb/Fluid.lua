local Constants = require("Constants")
local Helper = require("ingteb.Helper")
local Table = require("core.Table")
local Array = Table.Array
local Dictionary = Table.Dictionary
local ValueCache = require("core.ValueCache")
require("ingteb.Common")

function Fluid(name, prototype, database)
    local self = Common(name, prototype, database)
    self.object_name = "Fluid"
    self.SpriteType = "fluid"
    self.UsedBy = Dictionary:new{}
    self.CreatedBy = Dictionary:new{}

    self.RecipeList = Array:new{}

    function self:Setup() end

    return self
end

