QBCore = exports['qb-core']:GetCoreObject()
local offlineMedic = nil
local offlineAmbulance = nil
local carry = {
	InProgress = false,
	targetSrc = -1,
	type = "",
	personCarrying = {
		animDict = "missfinale_c2mcs_1",
		anim = "fin_c2_mcs_1_camman",
		flag = 49,
	},
	personCarried = {
		animDict = "nm",
		anim = "firemans_carry",
		attachX = 0.27,
		attachY = 0.15,
		attachZ = 0.63,
		flag = 33,
	}
}
local blip = nil
local hospitalLocations = {
    vector3(291.55, -606.26, 43.21),
    vector3(-466.62, -342.31, 34.37),
    vector3(1842.33, 3668.43, 33.68),
    vector3(-236.79, 6331.55, 32.4),
}
local shouldStop = false

local function ensureAnimDict(animDict)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end        
    end
    return animDict
end

function loadAnimDict( dict )
    RequestAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        Citizen.Wait( 3 )
    end
end

function CarryPerson()
    ensureAnimDict(carry.personCarried.animDict)
    TaskPlayAnim(PlayerPedId(), carry.personCarried.animDict, carry.personCarried.anim, 8.0, -8.0, 100000, carry.personCarried.flag, 0, false, false, false)
    TaskPlayAnim(offlineMedic, carry.personCarrying.animDict, carry.personCarrying.anim, 8.0, -8.0, 100000, carry.personCarrying.flag, 0, false, false, false)
	AttachEntityToEntity(PlayerPedId(), offlineMedic, 0, carry.personCarried.attachX, carry.personCarried.attachY, carry.personCarried.attachZ, 0.5, 0.5, 180, false, false, false, false, 2, false)
end

function PlaceInVehicle(vehicle)
	local playerPed = PlayerPedId()
	-- vehicle = NetworkGetEntityFromNetworkId(vehicle)
    print(vehicle)
	local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)
	for i=maxSeats - 1, 0, -1 do
		if IsVehicleSeatFree(vehicle, i) then
			freeSeat = i
			break
		end
	end
	if freeSeat then
		TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
	end
end

function setupMedicAndAmbulance()
    math.randomseed(GetGameTimer())
    local randX = math.random(-50, 50)
    local randY = math.random(-50, 50)
    local playerPed = PlayerPedId()

    local coords = GetEntityCoords(playerPed,true)

    -- if found then
    --     local spawned_car = CreateVehicle(vehicle, outPos, outHeading, true, false)
    --     SetVehicleOnGroundProperly(spawned_car)
    --     SetModelAsNoLongerNeeded(vehicle)
    -- end
    local coordsBehindPlayer = GetOffsetFromEntityInWorldCoords(playerPed, 100, -50.0, 0)
    local found, outPos, outHeading = GetClosestVehicleNodeWithHeading(coordsBehindPlayer['x'], coordsBehindPlayer['y'], coordsBehindPlayer['z'], 1, 3.0, 0)

    local playerHeading = GetEntityHeading(playerPed)
    local belowGround, groundZ, vec3OnFloor = GetGroundZAndNormalFor_3dCoord(coordsBehindPlayer.x + randX, coordsBehindPlayer.y + randY, coordsBehindPlayer.z)
    local AmbulanceHash = `ambulance`
    RequestModel(AmbulanceHash)
    while not HasModelLoaded(AmbulanceHash) do 
        Wait(5)
    end
    print("create car")
    -- offlineAmbulance = CreateVehicle(AmbulanceHash, coordsBehindPlayer.x, coordsBehindPlayer.y, groundZ, true, true)

    offlineAmbulance = CreateVehicle(AmbulanceHash, outPos.x, outPos.y, outPos.z, true, true)
    SetEntityHeading(offlineAmbulance, outHeading)
    exports['LegacyFuel']:SetFuel(offlineAmbulance, 100.0)
    local MedicHash = `a_c_chimp`
    RequestModel(MedicHash)
    while not HasModelLoaded(MedicHash) do
        Wait(5)
    end
    print("create person")
    offlineMedic = CreatePedInsideVehicle(offlineAmbulance, 30, MedicHash, -1, true, true)
    -- offlineMedic = CreatePed(30, MedicHash, coordsBehindPlayer.x, coordsBehindPlayer.y, groundZ + 1, playerHeading, true, true)
    SetModelAsNoLongerNeeded(MedicHash)
    SetPedFleeAttributes(offlineMedic, 0, 0)
    print("into car")
    Wait(100)
    SetPedIntoVehicle(offlineMedic, offlineAmbulance, -1)
    SetVehicleSiren(offlineAmbulance, true)
    blip = AddBlipForEntity(offlineMedic)
    SetBlipAsFriendly(blip, true)
    SetBlipSprite(blip, 51)
    SetBlipColour(blip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Monkey Medical")
    EndTextCommandSetBlipName(blip)
end

function findNearestHospital()
    local pCoords = GetEntityCoords(PlayerPedId())
    local nearest = hospitalLocations[1]
    local distance = #(pCoords - nearest)
    for i = 2, #hospitalLocations do
        if #(pCoords - hospitalLocations[i]) < distance then
            distance = #(pCoords - hospitalLocations[i])
            nearest = hospitalLocations[i]
        end
    end
    return nearest
end

function beginMonkeyMedical()

    setupMedicAndAmbulance()
    -- 524340
    monkeyMedical = true
    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    -- print("drive to")
    TaskVehicleDriveToCoordLongrange(offlineMedic, offlineAmbulance, pCoords.x, pCoords.y, pCoords.z, 60.0, 525100, 10.0)
    local mCoords = GetEntityCoords(offlineMedic)
    local timeout = 1
    while #(pCoords - mCoords) > 10.0 and not shouldStop do
        Wait(500)
        -- print("not close enough")
        pCoords = GetEntityCoords(playerPed)
        mCoords = GetEntityCoords(offlineMedic)
        timeout = timeout + 1
        print(timeout)
        if timeout >= 60 then
            -- print("took too long, restartting at new pos")
            cleanUp()
            print("reset 2")
            beginMonkeyMedical()
            return
        end
    end
    if shouldStop then
        print("should stop 4")
        cleanUp()
        return
    end
    -- print("close enough")
    TaskLeaveVehicle(offlineMedic, offlineAmbulance, 0)
    TaskGoToEntity(offlineMedic, playerPed, -1, 1.0, 1073741824, 0)
    pCoords = GetEntityCoords(playerPed)
    mCoords = GetEntityCoords(offlineMedic)
    while #(pCoords - mCoords) > 1.0 and not shouldStop do
        Wait(500)
        -- print("not close enough")
        pCoords = GetEntityCoords(playerPed)
        mCoords = GetEntityCoords(offlineMedic)
    end
    CarryPerson()
    Wait(500)
    TaskGoToEntity(offlineMedic, offlineAmbulance, -1, 0.5, 1073741824, 0)
    local aCoords = GetEntityCoords(offlineAmbulance)
    mCoords = GetEntityCoords(offlineMedic)
    while #(mCoords - aCoords) > 1.9 and not shouldStop do
        Wait(500)
        -- print("not close enough")
        -- print(#(mCoords - aCoords))
        aCoords = GetEntityCoords(offlineAmbulance)
        mCoords = GetEntityCoords(offlineMedic)
    end
    if shouldStop then
        print("should stop 3")
        cleanUp()
        return
    end
    -- print("at ambulance")
    ClearPedSecondaryTask(offlineMedic)
    ClearPedSecondaryTask(PlayerPedId())
    DetachEntity(offlineMedic, true, false)
    DetachEntity(PlayerPedId(), true, false)
    PlaceInVehicle(offlineAmbulance)
    Wait(250)
    SetPedIntoVehicle(offlineMedic, offlineAmbulance, -1)

    local nearestHospital = findNearestHospital()

    TaskVehicleDriveToCoordLongrange(offlineMedic, offlineAmbulance, nearestHospital.x, nearestHospital.y, nearestHospital.z, 80.0, 525100, 5.0)
    mCoords = GetEntityCoords(offlineMedic)
    -- print(nearestHospital)
    -- print(#(mCoords - nearestHospital))
    while #(mCoords - nearestHospital) > 10.0 and not shouldStop do
        Wait(500)
        mCoords = GetEntityCoords(offlineMedic)
    end
    if shouldStop then
        print("should stop 2")
        cleanUp()
        return
    end
    -- print("at hospital")
    SetVehicleSiren(offlineAmbulance, false)
    TaskLeaveVehicle(offlineMedic, offlineAmbulance, 16)
    TaskLeaveVehicle(playerPed, offlineAmbulance, 4160)
    Wait(1500)
    DeleteEntity(offlineAmbulance)
    offlineAmbulance = nil
    TaskGoToEntity(offlineMedic, playerPed, -1, 0.75, 1073741824, 0)
    pCoords = GetEntityCoords(playerPed)
    mCoords = GetEntityCoords(offlineMedic)
    local timer2 = 0
    while #(pCoords - mCoords) > 0.75 and not shouldStop do
        Wait(500)
        -- print("not close enough")
        timer2 = timer2 + 1
        pCoords = GetEntityCoords(playerPed)
        mCoords = GetEntityCoords(offlineMedic)
        
        if timer2 >= 30 then
            TriggerServerEvent("hospital:server:RespawnAtHospital")
            -- print("healed")
            monkeyMedical = false
            cleanUp()
            return
        end
    end
    if shouldStop then
        print("should stop 1")
        cleanUp()
        return
    end
    TaskTurnPedToFaceEntity(offlineMedic, playerPed, -1)
    loadAnimDict(healAnimDict)
    TaskPlayAnim(offlineMedic, healAnimDict, healAnim, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
    Wait(3000)
    local playerId = GetPlayerServerId(GetPlayerPed(PlayerPedId()))
    -- print(playerId)
    TriggerServerEvent("hospital:server:RespawnAtHospital")
    -- print("healed")
    monkeyMedical = false
    cleanUp()
end

-- dont even need to check cause of timeouts
-- Citizen.CreateThread(function()
--     while true do
--         local sleep = 5000
--         if monkeyMedical and not shouldStop then
--             sleep = 5
--             if IsPedDeadOrDying(offlineMedic) or GetVehicleEngineHealth(offlineAmbulance) < 300 and not shouldStop then
--                 print("restart 1")
--                 cleanUp()
--                 beginMonkeyMedical()
--             end
--         elseif shouldStop then
--             print("should stop 0")
--             cleanUp()
--         end
--         Wait(sleep)
--     end
-- end)

RegisterNetEvent('qb-ambulancejob:client:checkOfflineMedic')
AddEventHandler('qb-ambulancejob:client:checkOfflineMedic', function()
    local doctors = 0
    QBCore.Functions.TriggerCallback('hospital:GetDoctors', function(cb)
        doctors = cb
        if doctors == 0 and not offlineMedic then
            beginMonkeyMedical()
        else
            TriggerServerEvent('hospital:server:ambulanceAlert', 'Civilian Died')
        end
    end)
    
end)

RegisterNetEvent('hospital:client:reachedHospital', function()
    print("REACHED THE HOSPITAL, SHOULD STOP")
    shouldStop = true
    Wait(500)
    cleanUp()
end)

function cleanUp()
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) blip = nil end
    DetachEntity(PlayerPedId(), true, false)
    DetachEntity(PlayerPedId(), true, false)
    if offlineAmbulance then DeleteEntity(offlineAmbulance) offlineAmbulance = nil end
    if offlineMedic then DeleteEntity(offlineMedic) offlineMedic = nil end
    shouldStop = false
end


AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    ClearPedSecondaryTask(PlayerPedId())
    cleanUp()
end)
