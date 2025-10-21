local QBCore = exports['qb-core']:GetCoreObject()

-- Register usable item
QBCore.Functions.CreateUseableItem("repairkit", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    TriggerClientEvent('repairkit:use', source)
end)

-- Remove item after successful repair
RegisterNetEvent('repairkit:removeItem', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local hasItem = Player.Functions.GetItemByName('repairkit')
    
    if hasItem then
        Player.Functions.RemoveItem('repairkit', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['repairkit'], "remove")
    end
end)

-- -- Optional: Command to give repair kit (for testing)
-- QBCore.Commands.Add("giverepairkit", "Give yourself a repair kit (Admin Only)", {}, false, function(source)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if Player then
--         Player.Functions.AddItem('repairkit', 1)
--         TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['repairkit'], "add")
--     end
-- end, "admin")

-- Add item to qb-core/shared/items.lua
--[[
    ['repairkit'] = {
        ['name'] = 'repairkit',
        ['label'] = 'Repair Kit',
        ['weight'] = 2500,
        ['type'] = 'item',
        ['image'] = 'repairkit.png',
        ['unique'] = false,
        ['useable'] = true,
        ['shouldClose'] = true,
        ['combinable'] = nil,
        ['description'] = 'A repair kit to fix your vehicle'
    },
]]