local Constants = require("Constants")

local result = {Data = {}, Index = 0}

function result:new()
    local target = {}
    setmetatable(target, self)
    self.__index = self
    log("new "..serpent.block(self.Data) .." " ..self.Index)
    return target
end

function result:RemoveAll()
    log("RemoveAll count = "..#self.Data .." Index = " ..self.Index)
    self.Data = {}
    self.Index = 0
    log("RemoveAll count = "..#self.Data .." Index = " ..self.Index)
end

function result:HairCut(target)
    if target then
        log("HairCut start count = "..#self.Data .." Index = " ..self.Index)
        self.Index = self.Index + 1
        while #self.Data >= self.Index do table.remove(self.Data, self.Index) end
        self.Data[self.Index] = target
        log("HairCut count = "..#self.Data .." Index = " ..self.Index)
        return target
    end
end

function result:Back()
    if self.Index > 1 then
        log("Back start count = "..#self.Data .." Index = " ..self.Index)
        self.Index = self.Index - 1
        log("Back count = "..#self.Data .." Index = " ..self.Index)
        return self.Data[self.Index]
    end
end

function result:GetCurrent() 
    log("GetCurrent count = "..#self.Data .." Index = " ..self.Index)
    return     self.Data[self.Index] 
end

function result:Fore()
    if self.Index < #self.Data then
        log("Fore start count = "..#self.Data .." Index = " ..self.Index)
        self.Index = self.Index + 1
        log("Fore count = "..#self.Data .." Index = " ..self.Index)
        return self.Data[self.Index]
    end
end

function result:Save() 
    log("Save count = "..#self.Data .." Index = " ..self.Index)
    return {Data = self.Data, Index = self.Index} 
end

function result:Load(target)
    log("Load start count = "..#self.Data .." Index = " ..self.Index)
    if target then
        self.Data = target.Data
        self.Index = target.Index
    else
        self:RemoveAll()
    end
    log("Load count = "..#self.Data .." Index = " ..self.Index)

end

return result
