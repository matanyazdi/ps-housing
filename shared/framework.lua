Framework = {}

if IsDuplicityVersion() then
    Framework.ox = {}
    Framework.qb = {}

    function Framework.ox.Notify(src, message, type)
        type = type == "inform" and "info" or type
        TriggerClientEvent("ox_lib:notify", src, {title="Property", description=message, type=type})
    end

    function Framework.qb.Notify(src, message, type)
        type = type == "info" and "primary" or type
        TriggerClientEvent('QBCore:Notify', src, message, type)
    end

    function Framework.ox.RegisterInventory(stash, label, stashConfig)
        exports.ox_inventory:RegisterStash(stash, label, stashConfig.slots, stashConfig.maxweight, nil)
    end

    function Framework.qb.RegisterInventory(stash, label, stashConfig)
        -- Used for ox_inventory compat
    end

    function Framework.qb.SendLog(message)
        if Config.EnableLogs then
            TriggerEvent('qb-log:server:CreateLog', 'pshousing', 'Housing System', 'blue', message)
        end
    end
    
    function Framework.ox.SendLog(message)
            -- noop
    end

    return
end

local function hasApartment(apts)
    for propertyId, _  in pairs(apts) do
        local property = PropertiesTable[propertyId]
        if property.owner then
            return true
        end
    end

    return false
end

Framework.qb = {
    Notify = function(message, type)
        type = type == "info" and "primary" or type
        TriggerEvent('QBCore:Notify', message, type)
    end,
}

Framework.ox = {
    Notify = function(message, type)
        type = type == "inform" and "info" or type
        
        lib.notify({
            title = 'Property',
            description = message,
            type = type
        })
    end,
}
