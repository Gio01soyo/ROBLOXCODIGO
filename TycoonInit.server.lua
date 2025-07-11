-- File: ServerScriptService/src/Initializers/TycoonInit.server.lua
-- Responsable de generar una plataforma base para cada jugador (Tycoon) y teleport al unirse.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Carpeta donde se almacenarán las bases de jugadores
local basesFolder = workspace:FindFirstChild("PlayerBases")
if not basesFolder then
	basesFolder = Instance.new("Folder")
	basesFolder.Name = "PlayerBases"
	basesFolder.Parent = workspace
end

-- Define el tamaño y offsets de las plataformas
local PLATFORM_SIZE = Vector3.new(50, 1, 50)
local SPAWN_HEIGHT = 5
local GRID_OFFSET = Vector3.new(60, 0, 0)

-- Tabla para trackear la base de cada jugador
local playerBases = {}

-- Función para crear plataforma y teletransportar al jugador
local function createBaseForPlayer(player)
	-- Calcular posición en rejilla según UserId
	local index = (player.UserId % 10)
	local origin = Vector3.new(index * GRID_OFFSET.X, 0, 0)

	-- Crear modelo para la base
	local baseModel = Instance.new("Model")
	baseModel.Name = "Base_" .. player.Name
	baseModel.Parent = basesFolder

	-- Crear parte del suelo
	local ground = Instance.new("Part")
	ground.Name = "BasePlatform"
	ground.Size = PLATFORM_SIZE
	ground.Anchored = true
	ground.Position = origin + Vector3.new(0, -PLATFORM_SIZE.Y/2, 0)
	ground.Parent = baseModel

	-- Teleport al jugador al spawn point encima de la plataforma
	local function teleportCharacter(char)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(origin + Vector3.new(0, SPAWN_HEIGHT, 0))
		end
	end

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		teleportCharacter(player.Character)
	end
	player.CharacterAdded:Connect(teleportCharacter)

	playerBases[player.UserId] = baseModel
end

-- Crear base al unirse
Players.PlayerAdded:Connect(function(player)
	createBaseForPlayer(player)
end)

-- Evento en caso de que haya jugadores antes del script
for _, player in ipairs(Players:GetPlayers()) do
	createBaseForPlayer(player)
end

print("[TycoonInit] Inicialización de plataformas completada.")
