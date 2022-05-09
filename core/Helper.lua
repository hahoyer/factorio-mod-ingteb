local result = {}
function result.SnakeCaseToCamelCase(target, isLower)
  
  if not isLower then target = "_"..target end
  return target:gsub("_(.)",target.upper)
end

return result
