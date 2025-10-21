local QBCore = exports['qb-core']:GetCoreObject()
local isRepairing = false

-- Function to get vehicle's front position (bonnet area)
local function GetVehicleFrontPosition(vehicle)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    -- Use max.y for FRONT of vehicle (bonnet), min.y is the rear
    local frontOffset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, max.y + 0.5, 0.0)
    return frontOffset
end

-- Function to position player facing the bonnet
local function PositionPlayerAtBonnet(vehicle)
    local ped = PlayerPedId()
    local vehHeading = GetEntityHeading(vehicle)
    
    -- Get position at the front of vehicle (bonnet area)
    local bonnetPos = GetVehicleFrontPosition(vehicle)
    
    -- Set player position
    SetEntityCoords(ped, bonnetPos.x, bonnetPos.y, bonnetPos.z, false, false, false, false)
    
    -- Make player face towards the vehicle (same heading as vehicle to face the bonnet)
    SetEntityHeading(ped, vehHeading)
    
    Wait(100)
end

-- Function to load animation dictionary
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
    end
end

-- Function to play sitting repair animation
local function PlaySittingRepairAnim(ped)
    local animDict = "amb@world_human_vehicle_mechanic@male@base"
    local animName = "base"
    
    LoadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
end

-- Function to play laying down repair animation
local function PlayLayingRepairAnim(ped)
    local animDict = "mini@repair"
    local animName = "fixing_a_player"
    
    LoadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
end

-- Main repair kit use event
RegisterNetEvent('repairkit:use', function()
    if isRepairing then
        QBCore.Functions.Notify('You are already repairing a vehicle!', 'error')
        return
    end

    local ped = PlayerPedId()
    
    -- Check if player is in a vehicle
    if IsPedInAnyVehicle(ped, false) then
        QBCore.Functions.Notify('You must be outside the vehicle to use the repair kit!', 'error')
        return
    end

    -- Find nearest vehicle
    local coords = GetEntityCoords(ped)
    local vehicle = QBCore.Functions.GetClosestVehicle(coords)
    
    if not vehicle or vehicle == 0 or vehicle == -1 then
        QBCore.Functions.Notify('No vehicle nearby!', 'error')
        return
    end

    local vehCoords = GetEntityCoords(vehicle)
    local distance = #(coords - vehCoords)
    
    if distance > 5.0 then
        QBCore.Functions.Notify('You are too far from the vehicle!', 'error')
        return
    end

    -- Check if vehicle needs repair
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    
    if engineHealth >= 1000.0 and bodyHealth >= 1000.0 then
        QBCore.Functions.Notify('This vehicle doesn\'t need repairs!', 'error')
        return
    end

    -- Start repair process
    isRepairing = true
    
    QBCore.Functions.Notify('Opening bonnet...', 'primary', 2000)
    
    -- Open bonnet (door 4) - call twice to ensure it registers
    SetVehicleDoorOpen(vehicle, 4, false, false)
    Wait(100)
    SetVehicleDoorOpen(vehicle, 4, false, false)
    Wait(100)
    
    -- Force bonnet to stay open and prevent it from latching/breaking
    SetVehicleDoorLatched(vehicle, 4, false, false, false)
    
    Wait(800)
    
    -- Position player facing the bonnet
    PositionPlayerAtBonnet(vehicle)
    
    Wait(500)
    
    QBCore.Functions.Notify('Starting repair...', 'primary')
    
    -- STAGE 1: Sitting repair animation (first 7 seconds)
    PlaySittingRepairAnim(ped)
    
    -- First progress bar - Sitting repair
    QBCore.Functions.Progressbar("repair_stage1", "Inspecting engine...", 7000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Stage 1 Success
        
        -- STAGE 2: Laying down repair animation (next 8 seconds)
        ClearPedTasks(ped)
        Wait(300)
        
        -- Turn player 180 degrees to face the front of vehicle
        local currentHeading = GetEntityHeading(ped)
        local newHeading = currentHeading + 180.0
        if newHeading > 360.0 then
            newHeading = newHeading - 360.0
        end
        SetEntityHeading(ped, newHeading)
        
        Wait(200)
        
        PlayLayingRepairAnim(ped)
        
        QBCore.Functions.Notify('Fixing the damage...', 'primary')
        
        -- Second progress bar - Laying repair
        QBCore.Functions.Progressbar("repair_stage2", "Repairing engine...", 8000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Stage 2 Success (COMPLETE)
            
            -- Stop animation
            ClearPedTasksImmediately(ped)
            
            -- Repair vehicle completely
            SetVehicleFixed(vehicle)
            SetVehicleDeformationFixed(vehicle)
            SetVehicleUndriveable(vehicle, false)
            SetVehicleEngineHealth(vehicle, 1000.0)
            SetVehicleBodyHealth(vehicle, 1000.0)
            SetVehiclePetrolTankHealth(vehicle, 1000.0)
            
            -- Fix all doors except bonnet
            for i = 0, 3 do
                SetVehicleDoorShut(vehicle, i, false)
            end
            for i = 5, 5 do
                SetVehicleDoorShut(vehicle, i, false)
            end
            
            Wait(1000)
            
            -- Now close bonnet after everything is done
            SetVehicleDoorShut(vehicle, 4, false)
            
            -- Remove repair kit from inventory
            TriggerServerEvent('repairkit:removeItem')
            
            QBCore.Functions.Notify('Vehicle repaired successfully!', 'success')
            isRepairing = false
            
        end, function() -- Stage 2 Cancel
            ClearPedTasksImmediately(ped)
            SetVehicleDoorShut(vehicle, 4, false)
            QBCore.Functions.Notify('Repair cancelled!', 'error')
            isRepairing = false
        end)
        
    end, function() -- Stage 1 Cancel
        ClearPedTasksImmediately(ped)
        SetVehicleDoorShut(vehicle, 4, false)
        QBCore.Functions.Notify('Repair cancelled!', 'error')
        isRepairing = false
    end)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local ped = PlayerPedId()
        if isRepairing then
            ClearPedTasksImmediately(ped)
            isRepairing = false
        end
    end
end)