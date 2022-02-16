if script.active_mods["sonaxaton-research-queue-with-interface"] == nil then
    log {"ingteb-utility.optional-mod-not-present", "sonaxaton-research-queue-with-interface"}
    if script.active_mods["sonaxaton-research-queue"] == nil then
        log {"ingteb-utility.optional-mod-not-present", "sonaxaton-research-queue"}
        return nil
    end
end

if remote.interfaces["sonaxaton-research-queue"] == nil
    or remote.interfaces["sonaxaton-research-queue"]["get_queued_names"] == nil
    or remote.interfaces["sonaxaton-research-queue"]["enqueue"] == nil then
    log {"ingteb-utility.optional-mod-interface-not-present", "sonaxaton-research-queue"}
    return nil
end

log {"ingteb-utility.optional-mod-support-activated", "sonaxaton-research-queue"}

local Sonaxaton = {}

function Sonaxaton.GetQueue(force) --
    local result = remote.call("sonaxaton-research-queue", "get_queued_names", force)
    return result
end

function Sonaxaton.Enqueue(force, name)
    local result = remote.call("sonaxaton-research-queue", "enqueue", force, name)
    return result
end

return Sonaxaton
