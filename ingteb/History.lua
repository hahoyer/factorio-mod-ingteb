local Constants = require("Constants")
local class = require("core.class")

local dEventManager = class:new("EventManager")

local History = class:new("History")

function History:new()
    local instance = self:adopt{Data = {}, Index = 0}
    instance:properties{
        IsForePossible = {get = function() return instance.Index < #instance.Data end},
        IsBackPossible = {get = function() return instance.Index > 1 end},
    }
    return instance
end

function History:RemoveAll()
    log("RemoveAll start count = " .. #self.Data .. " Index = " .. self.Index)
    self.Data = {}
    self.Index = 0
    log("RemoveAll count = " .. #self.Data .. " Index = " .. self.Index)
end

function History:HairCut(target)
    if target then
        log("HairCut start count = " .. #self.Data .. " Index = " .. self.Index)
        self.Index = self.Index + 1
        while #self.Data >= self.Index do table.remove(self.Data, self.Index) end
        self.Data[self.Index] = target
        log("HairCut count = " .. #self.Data .. " Index = " .. self.Index)
        return target
    end
end

function History:Back()
    if self.Index > 1 then
        log("Back start count = " .. #self.Data .. " Index = " .. self.Index)
        self.Index = self.Index - 1
        log("Back count = " .. #self.Data .. " Index = " .. self.Index)
        return self.Data[self.Index]
    end
end

function History:GetCurrent()
    log("GetCurrent count = " .. #self.Data .. " Index = " .. self.Index)
    return self.Data[self.Index]
end

function History:Is()
    log("GetCurrent count = " .. #self.Data .. " Index = " .. self.Index)
    return self.Data[self.Index]
end

function History:Fore()
    if self.Index < #self.Data then
        log("Fore start count = " .. #self.Data .. " Index = " .. self.Index)
        self.Index = self.Index + 1
        log("Fore count = " .. #self.Data .. " Index = " .. self.Index)
        return self.Data[self.Index]
    end
end

function History:Save()
    log("Save count = " .. #self.Data .. " Index = " .. self.Index)
    return {Data = self.Data, Index = self.Index}
end

function History:Load(target)
    log("Load start count = " .. #self.Data .. " Index = " .. self.Index)
    if target then
        self.Data = target.Data
        self.Index = target.Index
    else
        self:RemoveAll()
    end
    log("Load count = " .. #self.Data .. " Index = " .. self.Index)

end

return History
