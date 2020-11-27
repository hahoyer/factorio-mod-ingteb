local Constants = require("Constants")
local class = require("core.class")

local History = class:new("History")

function History:new()
    local instance = self:adopt{Data = {}, Index = 0}
    self = instance
    instance:properties{
        IsForePossible = {get = function(self) return self.Index < #self.Data end},
        IsBackPossible = {get = function(self) return self.Index > 1 end},
        Current = {
            get = function(self) return self.Index > 0 and self.Data[self.Index] or nil end,
            set = function(self, value)
                if self.Index > 0 then self.Data[self.Index] = value end
            end,
        },
    }
    return instance
end

function History:Reset()
    self.Data = {}
    self.Index = 0
end

function History:Advance()
    while #self.Data > self.Index do table.remove(self.Data, self.Index) end
    self.Index = self.Index + 1
end

function History:Back()
    if self.Index > 1 then
        self.Index = self.Index - 1
    end
end

function History:Fore()
    if self.Index < #self.Data then
        self.Index = self.Index + 1
    end
end

function History:Save()
    return {Data = self.Data, Index = self.Index}
end

function History:Load(target)
    if target then
        self.Data = target.Data
        self.Index = target.Index
    else
        self:RemoveAll()
    end
end

return History
