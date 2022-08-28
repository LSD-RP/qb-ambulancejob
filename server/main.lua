local PlayerInjuries = {}
local PlayerWeaponWounds = {}
local doctorCount = 0
local QBCore = exports['qb-core']:GetCoreObject()
-- Events


function ExtractIdentifiers(src)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)

        if string.find(id, "steam") then
            identifiers.steam = id
        elseif string.find(id, "ip") then
            identifiers.ip = id
        elseif string.find(id, "discord") then
            identifiers.discord = id
        elseif string.find(id, "license") then
            identifiers.license = id
        elseif string.find(id, "xbl") then
            identifiers.xbl = id
        elseif string.find(id, "live") then
            identifiers.live = id
        end
    end

    return identifiers
end

function getPlayerLocation(src)

	local raw = LoadResourceFile(GetCurrentResourceName(), GetResourceMetadata(GetCurrentResourceName(), 'postal_file'))
	local postals = json.decode(raw)
	local nearest = nil

	local player = src
	local ped = GetPlayerPed(player)
	local playerCoords = GetEntityCoords(ped)

	local x, y = table.unpack(playerCoords)

	local ndm = -1
	local ni = -1
	for i, p in ipairs(postals) do
		local dm = (x - p.x) ^ 2 + (y - p.y) ^ 2
		if ndm == -1 or dm < ndm then
			ni = i
			ndm = dm
		end
	end

	if ni ~= -1 then
		local nd = math.sqrt(ndm)
		nearest = {i = ni, d = nd}
	end
	_nearest = postals[nearest.i].code
	return _nearest
end

function sanitize(string)
    return string:gsub('%@', '')
end

-- Compatibility with txAdmin Menu's heal options.
-- This is an admin only server side event that will pass the target player id or -1.
AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
	if GetInvokingResource() ~= "monitor" or type(eventData) ~= "table" or type(eventData.id) ~= "number" then
		return
	end

	TriggerClientEvent('hospital:client:Revive', eventData.id)
	TriggerClientEvent("hospital:client:HealInjuries", eventData.id, "full")
end)

RegisterNetEvent("hospital:server:SetDoctorCount", function(amount)
	doctorCount = amount
end)

RegisterNetEvent('hospital:server:SendToBed', function(bedId, isRevive)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	TriggerClientEvent('hospital:client:SendToBed', src, bedId, Config.Locations["beds"][bedId], isRevive)
	TriggerClientEvent('hospital:client:SetBed', -1, bedId, true)
	local cost = Config.BillCost
	local players = QBCore.Functions.GetQBPlayers()
	doctorCount = 0
    for k, v in pairs(players) do
		if v.PlayerData.job.name == "ambulance" then
			doctorCount = doctorCount + 1
		end
	end
	cost = cost * (doctorCount + 1)
	Player.Functions.RemoveMoney("bank", cost , "respawned-at-hospital")
		exports['qb-management']:AddMoney("ambulance", cost)
	TriggerClientEvent('hospital:client:SendBillEmail', src, cost)
end)

RegisterNetEvent('hospital:server:RespawnAtHospital', function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local playerCoords = GetEntityCoords(GetPlayerPed(src))
	local num = 1
	local bed = {}
	local dist = 9999999
	local players = QBCore.Functions.GetQBPlayers()
	doctorCount = 0
    for k, v in pairs(players) do
		if v.PlayerData.job.name == "ambulance" then
			doctorCount = doctorCount + 1
		end
	end
	TriggerClientEvent('hospital:client:reachedHospital', src)
	for k,v in pairs(Config.Locations["beds"]) do
		local vec = vector3(v.coords.x, v.coords.y, v.coords.z)
		if #(vec - playerCoords) < dist and k ~= 19 then
			-- print(k)
			-- print(v)
			num = k
			bed = v
			dist = #(vec - playerCoords)
		end
	end
	-- TriggerClientEvent('hospital:client:registerInHospital', src, true)
	for k, v in pairs(Config.Locations["beds"]) do
		if not v.taken then
			TriggerClientEvent('hospital:client:SendToBed', src, num, bed, true)
			TriggerClientEvent('hospital:client:SetBed', -1, num, true)
			print(("There are %d doctors online, and need %d"):format(doctorCount, Config.MinimalDoctors))
			if Config.WipeInventoryOnRespawn and doctorCount > Config.MinimalDoctors then
				Player.Functions.ClearInventory()
				MySQL.Async.execute('UPDATE players SET inventory = ? WHERE citizenid = ?', { json.encode({}), Player.PlayerData.citizenid })
				TriggerClientEvent('QBCore:Notify', src, Lang:t('error.possessions_taken'), 'error')
			end
		end

		TriggerClientEvent('hospital:client:SendToBed', src, 1, Config.Locations["jailbeds"][1], true)
		TriggerClientEvent('hospital:client:SetBed', -1, 1, true)
		if Config.WipeInventoryOnRespawn then
			Player.Functions.ClearInventory()
			MySQL.Async.execute('UPDATE players SET inventory = ? WHERE citizenid = ?', { json.encode({}), Player.PlayerData.citizenid })
			TriggerClientEvent('QBCore:Notify', src, Lang:t('error.possessions_taken'), 'error')
		end
		Player.Functions.RemoveMoney("bank", Config.BillCost, "respawned-at-hospital")
			exports['qb-management']:AddMoney("ambulance", Config.BillCost)
		TriggerClientEvent('hospital:client:SendBillEmail', src, Config.BillCost)
    end
	--print("All beds were full, placing in first bed as fallback")

	TriggerClientEvent('hospital:client:SendToBed', src, 1, Config.Locations["beds"][1], true)
	TriggerClientEvent('hospital:client:SetBed', -1, 1, true)
	print(("There are %d doctors online, and need %d"):format(doctorCount, Config.MinimalDoctors))
	if Config.WipeInventoryOnRespawn and doctorCount > Config.MinimalDoctors then
		Player.Functions.ClearInventory()
		MySQL.Async.execute('UPDATE players SET inventory = ? WHERE citizenid = ?', { json.encode({}), Player.PlayerData.citizenid })
		TriggerClientEvent('QBCore:Notify', src, Lang:t('error.possessions_taken'), 'error')
	end
	Player.Functions.RemoveMoney("bank", Config.BillCost, "respawned-at-hospital")
		exports['qb-management']:AddMoney("ambulance", Config.BillCost)
	TriggerClientEvent('hospital:client:SendBillEmail', src, Config.BillCost)
	-- TriggerClientEvent('hospital:client:registerInHospital', src, false)
end)

RegisterNetEvent('hospital:server:ambulanceAlert', function(text)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
	local arenaCenter = vector3(2801.07, -3797.48, 132.83)
	if #(coords - arenaCenter) > 500 then
		local players = QBCore.Functions.GetQBPlayers()
		for k,v in pairs(players) do
			if v.PlayerData.job.name == 'ambulance' then
				TriggerClientEvent('hospital:client:ambulanceAlert', v.PlayerData.source, coords, text)
			end
		end
	end
end)

RegisterNetEvent('hospital:server:LeaveBed', function(id)
    TriggerClientEvent('hospital:client:SetBed', -1, id, false)
end)

RegisterNetEvent('hospital:server:SyncInjuries', function(data)
    local src = source
    PlayerInjuries[src] = data
end)

RegisterNetEvent('hospital:server:SetWeaponDamage', function(data)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player then
		PlayerWeaponWounds[Player.PlayerData.source] = data
	end
end)

RegisterNetEvent('hospital:server:RestoreWeaponDamage', function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	PlayerWeaponWounds[Player.PlayerData.source] = nil
end)

RegisterNetEvent('hospital:server:SetDeathStatus', function(isDead)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player then
		Player.Functions.SetMetaData("isdead", isDead)
	end
end)

RegisterNetEvent('hospital:server:SetLaststandStatus', function(bool)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player then
		Player.Functions.SetMetaData("inlaststand", bool)
	end
end)

RegisterNetEvent('hospital:server:SetArmor', function(amount)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player then
		Player.Functions.SetMetaData("armor", amount)
	end
end)

RegisterNetEvent('hospital:server:TreatWounds', function(playerId)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Patient = QBCore.Functions.GetPlayer(playerId)
	if Patient then
		if Player.PlayerData.job.name =="ambulance" then
			Player.Functions.RemoveItem('bandage', 1)
			TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['bandage'], "remove")
			-- TriggerClientEvent("hospital:client:HealInjuries", Patient.PlayerData.source, "full")
			TriggerClientEvent('hospital:client:Revive', Patient.PlayerData.source)
		end
	end
end)

RegisterNetEvent('hospital:server:AddDoctor', function(job)
	if job == 'ambulance' then
		local src = source
		doctorCount = doctorCount + 1
		TriggerClientEvent("hospital:client:SetDoctorCount", -1, doctorCount)
		Doctors[src] = true
	end
end)

RegisterNetEvent('hospital:server:RemoveDoctor', function(job)
	if job == 'ambulance' then
		local src = source
		doctorCount = doctorCount - 1
		TriggerClientEvent("hospital:client:SetDoctorCount", -1, doctorCount)
		Doctors[src] = nil
	end
end)

AddEventHandler("playerDropped", function()
	local src = source
	if Doctors[src] then
		doctorCount = doctorCount - 1
		TriggerClientEvent("hospital:client:SetDoctorCount", -1, doctorCount)
		Doctors[src] = nil
	end
end)

RegisterNetEvent('hospital:server:RevivePlayer', function(playerId, isOldMan)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Patient = QBCore.Functions.GetPlayer(playerId)
	local oldMan = isOldMan or false
	if Patient then
		if oldMan then
			if Player.Functions.RemoveMoney("cash", 5000, "revived-player") then
				Player.Functions.RemoveItem('firstaid', 1)
				TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['firstaid'], "remove")
				TriggerClientEvent('hospital:client:Revive', Patient.PlayerData.source)
			else
				TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_enough_money'), "error")
			end
		else
			Player.Functions.RemoveItem('firstaid', 1)
			TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['firstaid'], "remove")
			TriggerClientEvent('hospital:client:Revive', Patient.PlayerData.source)
		end
	end
end)

RegisterNetEvent("hospital:server:RewardRevive", function(medic)
	local Player = QBCore.Functions.GetPlayer(source)
	Player.Functions.AddMoney('cash', 500)
end)

RegisterNetEvent('hospital:server:SendDoctorAlert', function(id)
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			TriggerClientEvent('QBCore:Notify', v.PlayerData.source, Lang:t('info.dr_needed'), 'ambulance')
		end
	end
end)

RegisterNetEvent('hospital:server:UseFirstAid', function(targetId)
	local src = source
	local Target = QBCore.Functions.GetPlayer(targetId)
	if Target then
		TriggerClientEvent('hospital:client:CanHelp', targetId, src)
	end
end)

RegisterNetEvent('hospital:server:CanHelp', function(helperId, canHelp)
	local src = source
	if canHelp then
		TriggerClientEvent('hospital:client:HelpPerson', helperId, src)
	else
		TriggerClientEvent('QBCore:Notify', helperId, Lang:t('error.cant_help'), "error")
	end
end)

RegisterNetEvent('hospital:server:removeBandage', function()
	local Player = QBCore.Functions.GetPlayer(source)

	if not Player then return end

	Player.Functions.RemoveItem('bandage', 1)
end)

RegisterNetEvent('hospital:server:removeIfaks', function()
	local Player = QBCore.Functions.GetPlayer(source)

	if not Player then return end

	Player.Functions.RemoveItem('ifaks', 1)
end)

RegisterNetEvent('hospital:server:removePainkillers', function()
	local Player = QBCore.Functions.GetPlayer(source)

	if not Player then return end

	Player.Functions.RemoveItem('painkillers', 1)
end)

RegisterNetEvent('hospital:server:resetHungerThirst', function()
	local Player = QBCore.Functions.GetPlayer(source)

	if not Player then return end

	Player.Functions.SetMetaData('hunger', 100)
	Player.Functions.SetMetaData('thirst', 100)

	TriggerClientEvent('hud:client:UpdateNeeds', source, 100, 100)
end)

-- Callbacks

QBCore.Functions.CreateCallback('hospital:GetDoctors', function(_, cb)
	local amount = 0
    local players = QBCore.Functions.GetQBPlayers()
    for k,v in pairs(players) do
        if v.PlayerData.job.name == 'ambulance' then
			amount = amount + 1
		end
	end
	cb(amount)
end)

QBCore.Functions.CreateCallback('hospital:GetPlayerStatus', function(_, cb, playerId)
	local Player = QBCore.Functions.GetPlayer(playerId)
	local injuries = {}
	injuries["WEAPONWOUNDS"] = {}
	if Player then
		if PlayerInjuries[Player.PlayerData.source] then
			if (PlayerInjuries[Player.PlayerData.source].isBleeding > 0) then
				injuries["BLEED"] = PlayerInjuries[Player.PlayerData.source].isBleeding
			end
			for k, _ in pairs(PlayerInjuries[Player.PlayerData.source].limbs) do
				if PlayerInjuries[Player.PlayerData.source].limbs[k].isDamaged then
					injuries[k] = PlayerInjuries[Player.PlayerData.source].limbs[k]
				end
			end
		end
		if PlayerWeaponWounds[Player.PlayerData.source] then
			for k, v in pairs(PlayerWeaponWounds[Player.PlayerData.source]) do
				injuries["WEAPONWOUNDS"][k] = v
			end
		end
	end
    cb(injuries)
end)

QBCore.Functions.CreateCallback('hospital:GetPlayerBleeding', function(source, cb)
	local src = source
	if PlayerInjuries[src] and PlayerInjuries[src].isBleeding then
		cb(PlayerInjuries[src].isBleeding)
	else
		cb(nil)
	end
end)

-- Commands

QBCore.Commands.Add('911e', Lang:t('info.ems_report'), {{name = 'message', help = Lang:t('info.message_sent')}}, false, function(source, args)
	local src = source
	local message
	if args[1] then message = table.concat(args, " ") else message = Lang:t('info.civ_call') end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
            TriggerClientEvent('hospital:client:ambulanceAlert', v.PlayerData.source, coords, message)
        end
    end
end)

QBCore.Commands.Add("status", Lang:t('info.check_health'), {}, false, function(source, _)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player.PlayerData.job.name == "ambulance" then
		TriggerClientEvent("hospital:client:CheckStatus", src)
	else
		TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_ems'), "error")
	end
end)

QBCore.Commands.Add("heal", Lang:t('info.heal_player'), {}, false, function(source, _)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player.PlayerData.job.name == "ambulance" then
		TriggerClientEvent("hospital:client:TreatWounds", src)
	else
		TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_ems'), "error")
	end
end)

QBCore.Commands.Add("revivep", Lang:t('info.revive_player'), {}, false, function(source, _)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player.PlayerData.job.name == "ambulance" then
		TriggerClientEvent("hospital:client:RevivePlayer", src)
	else
		TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_ems'), "error")
	end
end)

QBCore.Commands.Add("revive", Lang:t('info.revive_player_a'), {{name = "id", help = Lang:t('info.player_id')}}, false, function(source, args)
	local src = source
	if args[1] then
		local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
		if Player then
			TriggerClientEvent('hospital:client:Revive', Player.PlayerData.source)
		else
			TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_online'), "error")
		end
	else
		TriggerClientEvent('hospital:client:Revive', src)
	end
end, "admin")

QBCore.Commands.Add("setpain", Lang:t('info.pain_level'), {{name = "id", help = Lang:t('info.player_id')}}, false, function(source, args)
	local src = source
	if args[1] then
		local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
		if Player then
			TriggerClientEvent('hospital:client:SetPain', Player.PlayerData.source)
		else
			TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_online'), "error")
		end
	else
		TriggerClientEvent('hospital:client:SetPain', src)
	end
end, "admin")

QBCore.Commands.Add("kill", Lang:t('info.kill'), {{name = "id", help = Lang:t('info.player_id')}}, false, function(source, args)
	local src = source
	if args[1] then
		local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
		if Player then
			TriggerClientEvent('hospital:client:KillPlayer', Player.PlayerData.source)
		else
			TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_online'), "error")
		end
	else
		TriggerClientEvent('hospital:client:KillPlayer', src)
	end
end, "admin")

QBCore.Commands.Add('aheal', Lang:t('info.heal_player_a'), {{name = 'id', help = Lang:t('info.player_id')}}, false, function(source, args)
	local src = source
	if args[1] then
		local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
		if Player then
			TriggerClientEvent('hospital:client:adminHeal', Player.PlayerData.source)
		else
			TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_online'), "error")
		end
	else
		TriggerClientEvent('hospital:client:adminHeal', src)
	end
end, 'admin')

QBCore.Commands.Add('offlinemedic', '', {}, false, function(source, args)
	local src = source
	TriggerClientEvent('qb-ambulancejob:client:checkOfflineMedic', src)
end)

QBCore.Commands.Add('goawaymonkey', '', {}, false, function(source, args)
	local src = source
	TriggerClientEvent('hospital:client:reachedHospital', src)
	
end)
-- Items

QBCore.Functions.CreateUseableItem("ifaks", function(source, item)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player.Functions.RemoveItem("ifaks", 1) then
		TriggerClientEvent("hospital:client:UseIfaks", src)
	end
end)

QBCore.Functions.CreateUseableItem("bandage", function(source, item)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player.Functions.RemoveItem("bandage", 1) then
		TriggerClientEvent("hospital:client:UseBandage", src)
	end
end)

QBCore.Functions.CreateUseableItem("painkillers", function(source, item)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player.Functions.RemoveItem("painkillers", 1) then
		TriggerClientEvent("hospital:client:UsePainkillers", src)
	end
end)

QBCore.Functions.CreateUseableItem("firstaid", function(source, item)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player.Functions.GetItemByName(item.name) ~= nil then
		TriggerClientEvent("hospital:client:UseFirstAid", src)
	end
end)

exports('GetDoctorCount', function() return doctorCount end)

RegisterServerEvent('playerDied')
AddEventHandler('playerDied',function(id,player,killer,DeathReason,Weapon)
	local ids = ExtractIdentifiers(source)
	-- local postal = getPlayerLocation(source)
	local ped = GetPlayerPed(source)
	local postal = GetEntityCoords(ped, true)
	-- print(("source: %s"):format(source))
	if DeathReason then _DeathReason = "`"..DeathReason.."`" else _DeathReason = "`died`" end
	if Weapon then _Weapon = ""..Weapon.."" else _Weapon = "" end
	if Config.postal then _postal = "\n**Nearest Coords:** ".. postal .."" else _postal = "" end
	if Config.discordID then if ids.discord ~= "" then _discordID ="\n**Discord ID:** <@" ..ids.discord:gsub("discord:", "")..">" else _discordID = "\n**Discord ID:** N/A" end else _discordID = "" end
	if Config.steamID then if ids.steam ~= "" then _steamID ="\n**Steam ID:** " ..ids.steam.."" else _steamID = "\n**Steam ID:** N/A" end else _steamID = "" end
	if Config.steamURL then  if ids.steam ~= "" then _steamURL ="\nhttps://steamcommunity.com/profiles/" ..tonumber(ids.steam:gsub("steam:", ""),16).."" else _steamURL = "\n**Steam URL:** N/A" end else _steamID = "" end
	if Config.playerID then _playerID ="\n**Player ID:** " ..source.."" else _playerID = "" end

	if id == 1 then  -- Suicide/died
        discordLog('**' .. sanitize(GetPlayerName(source)) .. '** '.._DeathReason..''.._Weapon..''.._playerID..''.. _postal ..''.. _discordID..''.._steamID..''.._steamURL..'', Config.deathColor, 'deaths') -- sending to deaths channel
	elseif id == 2 then -- Killed by other player
		local ids2 = ExtractIdentifiers(killer)
		-- local postal2 = getPlayerLocation(killer)
		local ped2 = GetPlayerPed(killer)
		local postal2 = GetEntityCoords(ped2, true)
		if Config.postal then _postal2 = "\n**Nearest Coords:** ".. postal2 .."" else _postal2 = "" end
		if Config.discordID then if ids2.discord ~= "" then _KillDiscordID ="\n**Discord ID:** <@" ..ids2.discord:gsub("discord:", "")..">" else _KillDiscordID = "\n**Discord ID:** N/A" end else _KillDiscordID = "" end
		if Config.steamID then if ids2.steam ~= "" then _KillSteamID ="\n**Steam ID:** " ..ids2.steam.."" else _KillSteamID = "\n**Steam ID:** N/A" end else _KillSteamID = "" end
		if Config.steamURL then  if ids2.steam ~= "" then _KillSteamURL ="\nhttps://steamcommunity.com/profiles/" ..tonumber(ids2.steam:gsub("steam:", ""),16).."" else _KillSteamURL = "\n**Steam URL:** N/A" end else _steamID = "" end
		if Config.playerID then _killPlayerID ="\n**Player ID:** " ..killer.."" else _killPlayerID = "" end
		discordLog('**' .. GetPlayerName(killer) .. '** '.._DeathReason..' ' .. GetPlayerName(source).. ' `('.._Weapon..')`\n\n**[Player INFO]**'.._playerID..''.. _postal ..''.. _discordID..''.._steamID..''.._steamURL..'\n\n**[Killer INFO]**'.._killPlayerID..''.. _postal2 ..''.. _KillDiscordID..''.._KillSteamID..''.._KillSteamURL..'', Config.deathColor, 'deaths') -- sending to deaths channel
	else -- When gets killed by something else
        discordLog('**' .. sanitize(GetPlayerName(source)) .. '** `died`'.._playerID..''.. _postal ..''.. _discordID..''.._steamID..''.._steamURL..'', Config.deathColor, 'deaths') -- sending to deaths channel
	end
end)

function discordLog(message, color, channel)
	-- print(message)
	PerformHttpRequest('https://discord.com/api/webhooks/931728987535855679/9sa5pzyKjLDgo3jr_sbB_7tbNRDYlCRWltXz5xcI7dDeZPkuK6cCvz87137mBYRH93ye', function(err, text, headers) end, 'POST', json.encode({username = Config.username, embeds = {{["color"] = color, ["author"] = {["name"] = Config.communtiyName,["icon_url"] = Config.communtiyLogo}, ["description"] = "".. message .."",["footer"] = {["text"] = "© JokeDevil.com - "..os.date("%x %X %p"),["icon_url"] = "https://www.jokedevil.com/img/logo.png",},}}, avatar_url = Config.avatar}), { ['Content-Type'] = 'application/json' })
end
