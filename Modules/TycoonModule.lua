-- File: ServerScriptService/src/Modules/TycoonModule.lua
-- Responsabilidades:
--  - Gestión de base de operaciones: construcción y upgrades de talleres.
--  - Slots de bots de excavación.
--  - Multiplicadores pasivos por edificio.
--  - Integra EconomyModule para transacciones de moneda.

local DataStoreService   = game:GetService("DataStoreService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")

-- Bypass DataStore en Studio
local isStudio = RunService:IsStudio()
local function getDataStore(name)
	if isStudio then
		return {
			GetAsync = function() return nil end,
			SetAsync = function() end,
		}
	else
		return DataStoreService:GetDataStore(name)
	end
end

-- DataStore solo para estado de botSlots y estructuras
local tycoonStore = getDataStore("TycoonState")

-- Requerir EconomyModule
local srcFolder       = game.ServerScriptService:WaitForChild("src")
local modulesFolder   = srcFolder:WaitForChild("Modules")
local EconomyModule   = require(modulesFolder:WaitForChild("EconomyModule"))

-- Remotes en ReplicatedStorage
local tycoonRemotes      = ReplicatedStorage:WaitForChild("TycoonRemotes")
local BuildStructureRF   = tycoonRemotes:WaitForChild("BuildStructure")
local UpgradeStructureRF = tycoonRemotes:WaitForChild("UpgradeStructure")
local GetBotCountRF      = tycoonRemotes:WaitForChild("GetBotCount")
local BuyBotSlotRF       = tycoonRemotes:WaitForChild("BuyBotSlot")
local PassiveIncomeRF    = tycoonRemotes:WaitForChild("CalculatePassiveIncome")

local TycoonModule = {}
TycoonModule.__index = TycoonModule

-- Definiciones de estructuras y costos
local STRUCTURES = {
	Taller = { cost = 30, baseMultiplier = 1.0, upgradeCostFactor = 1.5 },
	RefineriaAvanzada = { cost = 500, baseMultiplier = 2.0, upgradeCostFactor = 1.7 },
}

-- Estado en memoria: playerId -> { botSlots = n, structures = { ... } }
local playerStates = {}

-- Cargar estado (botSlots y estructuras) desde DataStore
local function loadState(player)
	local key = tostring(player.UserId)
	local success, data = pcall(function()
		return tycoonStore:GetAsync(key)
	end)
	if success and type(data) == "table" then
		playerStates[player.UserId] = data
	else
		playerStates[player.UserId] = { botSlots = 1, structures = {} }
	end
	return playerStates[player.UserId]
end

-- Guardar estado (botSlots y estructuras)
local function saveState(player)
	local key = tostring(player.UserId)
	local state = playerStates[player.UserId]
	if type(state) ~= "table" then return end
	pcall(function()
		tycoonStore:SetAsync(key, state)
	end)
end

-- Inicializa estado de jugador
function TycoonModule:InitPlayer(player)
	loadState(player)
end

-- Guarda estado al desconectar
function TycoonModule:SavePlayer(player)
	saveState(player)
end

-- Construir estructura: usa EconomyModule para descontar monedas
function TycoonModule:BuildStructure(player, structureType)
	-- Validar tipo
	local spec = STRUCTURES[structureType]
	if not spec then
		return false, "Tipo inválido"
	end
	-- Intentar gastar monedas arcanas
	local ok, err = EconomyModule:SpendCurrency(player, "ArcaneCoins", spec.cost)
	if not ok then
		return false, err or "Créditos insuficientes"
	end
	-- Registrar estructura
	local state = playerStates[player.UserId] or loadState(player)
	local id = structureType .. "_" .. tostring(os.time())
	state.structures[id] = { type = structureType, level = 1 }
	-- Persistir cambios de estado de estructuras
	saveState(player)
	return true, id
end

-- Mejorar estructura: calcula coste e usa EconomyModule
function TycoonModule:UpgradeStructure(player, structureId)
	local state = playerStates[player.UserId] or loadState(player)
	local info = state.structures[structureId]
	if not info then
		return nil, "Estructura no encontrada"
	end
	local spec = STRUCTURES[info.type]
	-- Coste basado en nivel actual
	local cost = math.floor(spec.cost * (spec.upgradeCostFactor ^ info.level))
	-- Intentar gastar
	local ok, err = EconomyModule:SpendCurrency(player, "ArcaneCoins", cost)
	if not ok then
		return nil, err or "Créditos insuficientes"
	end
	-- Aumentar nivel y guardar
	info.level = info.level + 1
	saveState(player)
	return info.level
end

-- Obtener número de slots de bots
function TycoonModule:GetBotCount(player)
	local state = playerStates[player.UserId] or loadState(player)
	return state.botSlots
end

-- Comprar slot de bot: debitar monedas y aumentar slot
function TycoonModule:BuyBotSlot(player)
	local state = playerStates[player.UserId] or loadState(player)
	local slotCost = 200 * state.botSlots
	local ok, err = EconomyModule:SpendCurrency(player, "ArcaneCoins", slotCost)
	if not ok then
		return false, err or "Créditos insuficientes"
	end
	state.botSlots = state.botSlots + 1
	saveState(player)
	return true
end

-- Calcular ingresos pasivos durante deltaTime segundos
function TycoonModule:CalculatePassiveIncome(player, deltaTime)
	local state = playerStates[player.UserId] or loadState(player)
	local totalMultiplier = 1.0
	for _, info in pairs(state.structures) do
		local spec = STRUCTURES[info.type]
		totalMultiplier = totalMultiplier + (spec.baseMultiplier * info.level)
	end
	local income = 1 * totalMultiplier * deltaTime
	-- Añadir al balance usando EconomyModule
	EconomyModule:AddCurrency(player, "ArcaneCoins", income)
	return income
end

-- Conectar Remotes (solo servidor)
if RunService:IsServer() then
	BuildStructureRF.OnServerInvoke   = function(player, structureType)
		return TycoonModule:BuildStructure(player, structureType)
	end
	UpgradeStructureRF.OnServerInvoke = function(player, structureId)
		return TycoonModule:UpgradeStructure(player, structureId)
	end
	GetBotCountRF.OnServerInvoke      = function(player)
		return TycoonModule:GetBotCount(player)
	end
	BuyBotSlotRF.OnServerInvoke       = function(player)
		return TycoonModule:BuyBotSlot(player)
	end
	PassiveIncomeRF.OnServerInvoke    = function(player, deltaTime)
		return TycoonModule:CalculatePassiveIncome(player, deltaTime)
	end
end

return TycoonModule
