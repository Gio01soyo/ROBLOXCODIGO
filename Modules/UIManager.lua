-- File: ServerScriptService/src/Modules/UIManager.lua
--!strict
--[[
    UIManager: orquesta todas las interfaces de usuario (HUD, menús, paneles, notificaciones, ranking).
    Abstrae la lógica de vistas para que otros módulos solo disparen eventos o funciones remotas.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Requerir EconomyModule para suscripción a cambios de balance
local srcFolder = game.ServerScriptService:WaitForChild("src")
local modulesFolder = srcFolder:WaitForChild("Modules")
local EconomyModule = require(modulesFolder:WaitForChild("EconomyModule"))

-- Carpeta de remotes UI
local uiRemotes = ReplicatedStorage:WaitForChild("UIRemotes")

-- RemoteFunctions/Events (plantilla)
local RequestMissionsRF = uiRemotes:FindFirstChild("RequestMissions") :: RemoteFunction?
local MissionCompletedRE = uiRemotes:FindFirstChild("MissionCompleted") :: RemoteEvent?

local UIManager = {} :: {
	__index: any,
	ShowResourceHUD: (self: any, player: Player) -> (),
	ShowShopMenu: (self: any, player: Player) -> (),
	UpdateShopMenu: (self: any, player: Player) -> (),
	ShowMissionsPanel: (self: any, player: Player) -> (),
	UpdateMissionStatus: (self: any, player: Player, missionData: any) -> (),
	Notify: (self: any, player: Player, title: string, message: string, duration: number) -> (),
	ShowLeaderboard: (self: any, player: Player, boardType: string) -> (),
	Init: (self: any) -> (),
}
UIManager.__index = UIManager

-- Template tables for storing GUI instances per player
local playerGuis: {[number]: {resourceHUD: ScreenGui?}} = {}

--[[
    Muestra el HUD de recursos (balances con íconos).
    @param player Player
]]
function UIManager:ShowResourceHUD(player: Player)
	error("Not yet implemented")
end

--[[
    Muestra el menú de tienda y cofres.
]]
function UIManager:ShowShopMenu(player: Player)
	error("Not yet implemented")
end

--[[
    Actualiza el contenido del menú de tienda.
]]
function UIManager:UpdateShopMenu(player: Player)
	error("Not yet implemented")
end

--[[
    Muestra el panel de misiones diarias y reto semanal.
]]
function UIManager:ShowMissionsPanel(player: Player)
	error("Not yet implemented")
end

--[[
    Actualiza la vista de una misión específica.
    @param missionData table
]]
function UIManager:UpdateMissionStatus(player: Player, missionData: any)
	error("Not yet implemented")
end

--[[
    Muestra una notificación temporal.
    @param title string
    @param message string
    @param duration number (segundos)
]]
function UIManager:Notify(player: Player, title: string, message: string, duration: number)
	error("Not yet implemented")
end

--[[
    Muestra la tabla de líderes (top 10).
    @param boardType string
]]
function UIManager:ShowLeaderboard(player: Player, boardType: string)
	error("Not yet implemented")
end

--[[
    Inicializa UIManager: crea HUD de recursos y suscripciones.
]]
function UIManager:Init()
	-- Conectar para cada jugador al entrar
	Players.PlayerAdded:Connect(function(player)
		-- Crear HUD de recursos
		self:ShowResourceHUD(player)
		-- Suscribirse a cambios de balance
		-- Se asume EconomyModule expone un RemoteEvent "BalanceChanged"
		local rem = ReplicatedStorage:WaitForChild("EconomyRemotes"):WaitForChild("BalanceChanged") :: RemoteEvent
		rem.OnClientEvent:Connect(function(currencyType: string, newAmount: number)
			if player == Players.LocalPlayer then
				-- Actualizar HUD local
				local gui = playerGuis[player.UserId]
				if gui and gui.resourceHUD then
					-- Lógica interna para refrescar texto e íconos
					-- TODO: implementar actualizar campos
				end
			end
		end)
	end)
end

-- Ejecutar Init en el servidor
task.defer(function()
	UIManager:Init()
end)

return UIManager
