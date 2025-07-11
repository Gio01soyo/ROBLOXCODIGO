-- File: ServerScriptService/src/Modules/EconomyModule.lua
-- Responsabilidades:
--  - Control de monedas arcanas, reliquias doradas y gemas eternas.
--  - Persistencia de datos (DataStore) con bypass en Studio.
--  - Emisión de eventos a cliente via RemoteEvent.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Determinar modo Studio
local isStudio = RunService:IsStudio()

-- DataStore para estado económico (solo en producción)
local ecoStore = not isStudio and DataStoreService:GetDataStore("EcoState") or nil

-- Carpeta de remotes en ReplicatedStorage
local econRemotes = ReplicatedStorage:WaitForChild("EconomyRemotes")
-- RemoteFunctions
local ReqBal = econRemotes:WaitForChild("RequestBalance")
local ReqAdd = econRemotes:WaitForChild("RequestAdd")
local ReqSpend = econRemotes:WaitForChild("RequestSpend")
-- RemoteEvent para balance changed
local BalanceChangedRE = econRemotes:FindFirstChild("BalanceChanged")
if not BalanceChangedRE then
	BalanceChangedRE = Instance.new("RemoteEvent")
	BalanceChangedRE.Name = "BalanceChanged"
	BalanceChangedRE.Parent = econRemotes
end

local EconomyModule = {}
EconomyModule.__index = EconomyModule

-- Cache en memoria: playerId -> balances
local playerBalances = {}

-- Validar tipos de moneda
local supportedCurrencies = {
	ArcaneCoins = true,
	GoldenRelics = true,
	EternalGems = true,
}

-- Carga o inicializa balances
function EconomyModule:LoadData(player)
	if not player then return end
	local key = tostring(player.UserId)
	-- En Studio, inicializar sin DataStore
	if isStudio then
		playerBalances[player.UserId] = { ArcaneCoins = 0, GoldenRelics = 0, EternalGems = 0 }
		return
	end
	-- Producción: leer DataStore
	local success, data = pcall(function()
		return ecoStore:GetAsync(key)
	end)
	if success and type(data) == "table" then
		playerBalances[player.UserId] = data
	else
		playerBalances[player.UserId] = { ArcaneCoins = 0, GoldenRelics = 0, EternalGems = 0 }
	end
end

-- Guarda balances (solo en producción)
function EconomyModule:SaveData(player)
	if isStudio then return end
	local key = tostring(player.UserId)
	local balance = playerBalances[player.UserId]
	if type(balance) ~= "table" then return end
	pcall(function()
		ecoStore:SetAsync(key, balance)
	end)
end

-- Obtiene el balance actual
function EconomyModule:GetBalance(player, currencyType)
	if not supportedCurrencies[currencyType] then
		warn("[EconomyModule] Tipo no soportado: " .. tostring(currencyType))
		return 0
	end
	if not playerBalances[player.UserId] then
		self:LoadData(player)
	end
	return playerBalances[player.UserId][currencyType] or 0
end

-- Añade cantidad y notifica al cliente
function EconomyModule:AddCurrency(player, currencyType, amount)
	if not supportedCurrencies[currencyType] then return false, "Moneda no soportada" end
	if amount <= 0 then return false, "Cantidad debe ser positiva" end
	if not playerBalances[player.UserId] then self:LoadData(player) end
	playerBalances[player.UserId][currencyType] = playerBalances[player.UserId][currencyType] + amount
	-- Persistir y notificar
	self:SaveData(player)
	BalanceChangedRE:FireClient(player, currencyType, playerBalances[player.UserId][currencyType])
	return true
end

-- Resta cantidad si hay saldo suficiente y notifica
function EconomyModule:SpendCurrency(player, currencyType, amount)
	if not supportedCurrencies[currencyType] then return false, "Moneda no soportada" end
	if amount <= 0 then return false, "Cantidad debe ser positiva" end
	if not playerBalances[player.UserId] then self:LoadData(player) end
	local current = playerBalances[player.UserId][currencyType]
	if current < amount then return false, "Saldo insuficiente" end
	playerBalances[player.UserId][currencyType] = current - amount
	-- Persistir y notificar
	self:SaveData(player)
	BalanceChangedRE:FireClient(player, currencyType, playerBalances[player.UserId][currencyType])
	return true
end

-- Conexión de remotes (solo servidor)
if RunService:IsServer() then
	ReqBal.OnServerInvoke = function(player, currencyType)
		return EconomyModule:GetBalance(player, currencyType)
	end
	ReqAdd.OnServerInvoke = function(player, currencyType, amount)
		return EconomyModule:AddCurrency(player, currencyType, amount)
	end
	ReqSpend.OnServerInvoke = function(player, currencyType, amount)
		return EconomyModule:SpendCurrency(player, currencyType, amount)
	end

	-- Auto-save cada 5 minutos y al desconectar
	Players.PlayerRemoving:Connect(function(pl) EconomyModule:SaveData(pl) end)
	spawn(function()
		while true do wait(300)
			for _, pl in ipairs(Players:GetPlayers()) do
				EconomyModule:SaveData(pl)
			end
		end
	end)
	-- Cargar al conectar
	Players.PlayerAdded:Connect(function(pl) EconomyModule:LoadData(pl) end)
end

return EconomyModule
