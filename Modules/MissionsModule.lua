-- File: ServerScriptService/src/Modules/MissionsModule.lua
--!strict
--[[
    Módulo de Misiones: administra tareas diarias y retos semanales
    Genera, asigna, rastrea progreso y entrega recompensas.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- DataStore para estado de misiones
local missionsStore = DataStoreService:GetDataStore("MissionsState")

-- Carpeta de remotes
local remotesFolder = ReplicatedStorage:WaitForChild("MissionsRemotes")
local RequestMissionsRF = remotesFolder:WaitForChild("RequestMissions") :: RemoteFunction
local ReportProgressRE = remotesFolder:WaitForChild("ReportProgress") :: RemoteEvent
local MissionCompletedRE = remotesFolder:WaitForChild("MissionCompleted") :: RemoteEvent

export type MissionData = {
	id: string,
	description: string,
	targetAmount: number,
	rewardType: string,
	rewardValue: number,
	progress: number,
	completed: boolean,
}

export type ChallengeData = {
	id: string,
	description: string,
	startDate: number,
	endDate: number,
	globalProgress: {[string]: number},
}

local MissionsModule = {} :: {
	__index: any,
	GenerateDailyMissions: (self: any, player: Player) -> {MissionData},
	GenerateWeeklyChallenge: (self: any) -> ChallengeData,
	ReportProgress: (self: any, player: Player, missionId: string, amount: number) -> (),
	GrantReward: (self: any, player: Player, missionId: string) -> (),
	LoadPlayerMissions: (self: any, player: Player) -> (),
	SavePlayerMissions: (self: any, player: Player) -> (),
	Init: (self: any) -> (),
}
MissionsModule.__index = MissionsModule

-- Tablas en memoria por jugador
local playerMissions: {[number]: {daily: {MissionData}, weekly: ChallengeData}} = {}

--[[
    Carga misiones del DataStore o inicializa estructura vacía.
]]
function MissionsModule:LoadPlayerMissions(player: Player)
	error("Not yet implemented")
end

--[[
    Guarda misiones del jugador en DataStore.
]]
function MissionsModule:SavePlayerMissions(player: Player)
	error("Not yet implemented")
end

--[[
    Genera 3-5 misiones diarias aleatorias para el jugador.
    @param player Player
    @return tabla de MissionData
]]
function MissionsModule:GenerateDailyMissions(player: Player): {MissionData}
	error("Not yet implemented")
end

--[[
    Genera el reto semanal global.
    @return ChallengeData
]]
function MissionsModule:GenerateWeeklyChallenge(): ChallengeData
	error("Not yet implemented")
end

--[[
    Reporta progreso para una misión y marca completada si alcanza el objetivo.
    @param player Player
    @param missionId string
    @param amount number
]]
function MissionsModule:ReportProgress(player: Player, missionId: string, amount: number)
	error("Not yet implemented")
end

--[[
    Otorga la recompensa correspondiente a la misión completada.
    @param player Player
    @param missionId string
]]
function MissionsModule:GrantReward(player: Player, missionId: string)
	error("Not yet implemented")
end

-- Conexión de remotes
if RunService:IsServer() then
	RequestMissionsRF.OnServerInvoke = function(player: Player)
		return playerMissions[player.UserId] or {}
	end
	ReportProgressRE.OnServerEvent:Connect(function(player: Player, missionId: string, amount: number)
		MissionsModule:ReportProgress(player, missionId, amount)
	end)
end

--[[
    Init de prueba: genera misiones para un jugador simulado y reporta progreso.
]]
function MissionsModule:Init()
	-- Simular jugador de prueba
	local mockPlayer = {UserId = 0, Name = "Tester"} :: Player
	print("[MissionsModule] Init: Generando misiones diarias para jugador de prueba...")
	local missions = self:GenerateDailyMissions(mockPlayer)
	for _, m in ipairs(missions) do
		print("  Misión:", m.id, m.description)
		print("    Progreso inicial:", m.progress, "/", m.targetAmount)
		-- Reportar parte del progreso
		self:ReportProgress(mockPlayer, m.id, math.floor(m.targetAmount/2))
		-- Reportar completado
		self:ReportProgress(mockPlayer, m.id, m.targetAmount)
	end
	print("[MissionsModule] Init finalizado.")
end

return MissionsModule
