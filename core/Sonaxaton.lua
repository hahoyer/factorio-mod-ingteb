local Sonaxaton = {}

local function IsValid()
    if script.active_mods["sonaxaton-research-queue-with-interface"] == nil then
        log {"ingteb-utility.optional-mod-not-present", "sonaxaton-research-queue-with-interface"}
        if script.active_mods["sonaxaton-research-queue"] == nil then
            log {"ingteb-utility.optional-mod-not-present", "sonaxaton-research-queue"}
            return false
        end
    end

    if remote.interfaces["sonaxaton-research-queue"] == nil
        or remote.interfaces["sonaxaton-research-queue"]["get_queued_names"] == nil
        or remote.interfaces["sonaxaton-research-queue"]["enqueue"] == nil then
        log {"ingteb-utility.optional-mod-interface-not-present", "sonaxaton-research-queue"}
        return false
    end

    log {"ingteb-utility.optional-mod-support-activated", "sonaxaton-research-queue"}

    return true
end

function Sonaxaton.IsValid()
    if Sonaxaton.IsValidCache == nil then Sonaxaton.IsValidCache = IsValid() end
    return Sonaxaton.IsValidCache
end

function Sonaxaton.GetQueue(force) --
    local result = remote.call("sonaxaton-research-queue", "get_queued_names", force)
    return result
end

function Sonaxaton.Enqueue(force, name)
    local result = remote.call("sonaxaton-research-queue", "enqueue", force, name)
    return result
end

return Sonaxaton
