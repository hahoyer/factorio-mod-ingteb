local result = {}
function result.SnakeCaseToCamelCase(target, isLower)

  if not isLower then target = "_" .. target end
  return target:gsub("_(.)", target.upper)
end

---@param data table
---@param key string
---@param value any
---@return table
function result.EnsureKey(data, key, value)
  local result = data[key]
  if not result then
    result = value or {}
    data[key] = result
  end
  return result
end

---@param target table
---@param keys string[]
---@return table
function result.EnsureKeys(target, keys)
  for _, key in ipairs(keys) do
    local element = target[key]
    if not element then
      element = {}
      target[key] = element
    end
    target = element
  end
  return target
end

function result.GetObjectType(prototype)
  local objectName = prototype.object_name
  if not objectName then return end
  return objectName == "LuaFluidPrototype" and "fluid"
      or objectName == "LuaFluidBoxPrototype" and "fluid_box"
      or objectName == "LuaItemPrototype" and "item"
      or objectName == "LuaEntityPrototype" and "entity"
      or objectName == "LuaRecipePrototype" and "recipe"
      or objectName == "LuaTechnologyPrototype" and "technology"
      or objectName == "LuaGroup" and "group"
      or dassert(false)
end

return result
