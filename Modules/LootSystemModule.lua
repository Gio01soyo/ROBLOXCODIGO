-- ModuleScript: src/Modules/LootSystemModule.lua
-- Ubicación: ServerScriptService/src/Modules/LootSystemModule (ModuleScript)
-- Script de inicialización: ServerScriptService/LootInit.server.lua
-- ReplicatedStorage/LootRemotes (Folder) con:
--  • RemoteFunction "OpenChest"
--  • RemoteFunction "GetPityCounter"

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- DataStore para pity counters
local pityStore = DataStoreService:GetDataStore("LootPity")

-- Dependencia a EconomyModule (opcional)
-- local EconomyModule = require(game.ServerScriptService.src.Modules.EconomyModule)

local LootSystemModule = {}
LootSystemModule.__index = LootSystemModule

-- Eventos para UI y lógica externa
LootSystemModule.OnChestOpened = Instance.new("BindableEvent")
LootSystemModule.OnPityReset   = Instance.new("BindableEvent")

-- Configuración de cofres y probabilidades
local ChestConfigs = {
	Basic = { weights = { Common = 60, Uncommon = 25, Rare = 10, Epic = 4, Legendary = 1 }, pity = 50 },
	Advanced = { weights = { Common = 50, Uncommon = 30, Rare = 12, Epic = 6, Legendary = 2 }, pity = 40 },
	Event = { weights = { Common = 40, Uncommon = 30, Rare = 15, Epic = 10, Legendary = 5 }, pity = 30 },
}

--[[
    Carga pity counter del jugador
    @param player Player
    @return number count
]]
function LootSystemModule:LoadPity(player)
	error("Not yet implemented")
end

--[[
    Guarda pity counter del jugador
    @param player Player
    @param count number
]]
function LootSystemModule:SavePity(player, count)
	error("Not yet implemented")
end

--[[
    Abre un cofre, aplica probabilidades y pity counter
    @param player Player
    @param chestType string
    @return string itemId, string rarity
]]
function LootSystemModule:OpenChest(player, chestType)
	error("Not yet implemented")
end

--[[
    Devuelve el pity counter actual
    @param player Player
    @param chestType string
    @return number count
]]
function LootSystemModule:GetPityCounter(player, chestType)
	error("Not yet implemented")
end

--[[
    Resetea el pity counter del jugador
    @param player Player
    @param chestType string
]]
function LootSystemModule:ResetPityCounter(player, chestType)
	error("Not yet implemented")
end

-- Conexión de Remotes (solo servidor)
if RunService:IsServer() then
	local lootRemotes = ReplicatedStorage:WaitForChild("LootRemotes")
	local OpenChestRF    = lootRemotes:WaitForChild("OpenChest") :: RemoteFunction
	local GetPityRF      = lootRemotes:WaitForChild("GetPityCounter") :: RemoteFunction

	OpenChestRF.OnServerInvoke = function(player, chestType)
		return LootSystemModule:OpenChest(player, chestType)
	end
	GetPityRF.OnServerInvoke = function(player, chestType)
		return LootSystemModule:GetPityCounter(player, chestType)
	end
end

--[[
    Init: simula aperturas de cofres para test
    Archivo: ServerScriptService/LootInit.server.lua (Script)
]]
function LootSystemModule.Init()
	local mockPlayer = {UserId = 0}
	-- Simular 10 aperturas de "Basic"
	for i = 1, 10 do
		local itemId, rarity = LootSystemModule:OpenChest(mockPlayer, "Basic")
		print(string.format("Test OpenChest #%d: %s - %s", i, itemId or "nil", rarity or "nil"))
		local pity = LootSystemModule:GetPityCounter(mockPlayer, "Basic")
		print("Pity counter now:", pity)
	end
end

return LootSystemModule
