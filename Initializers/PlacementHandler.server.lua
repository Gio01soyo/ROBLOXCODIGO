-- File: ServerScriptService/src/Initializers/PlacementHandler.server.lua
-- Maneja la colocación de prefabs en base del jugador tras construcción

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Requerir TycoonModule para transacciones
local srcFolder      = game.ServerScriptService:WaitForChild("src")
local modulesFolder  = srcFolder:WaitForChild("Modules")
local TycoonModule   = require(modulesFolder:WaitForChild("TycoonModule"))

local TycoonRemotes = ReplicatedStorage:WaitForChild("TycoonRemotes")
-- RemoteFunction para colocar estructuras
local PlaceStructureRF = Instance.new("RemoteFunction")
PlaceStructureRF.Name = "PlaceStructure"
PlaceStructureRF.Parent = TycoonRemotes

-- Prefabs de estructuras en ReplicatedStorage.Structures
local prefabFolder = ReplicatedStorage:WaitForChild("Structures")

-- Folder con bases de jugadores
local basesFolder = workspace:WaitForChild("PlayerBases")

-- OnServerInvoke: recibe estructura y posición
PlaceStructureRF.OnServerInvoke = function(player, structureType, position)
	-- Ejecutar lógica de construcción (descuenta monedas y registra ID)
	local success, result = TycoonModule:BuildStructure(player, structureType)
	if not success then
		return false, result -- mensaje de error
	end
	local structureId = result
	-- Buscar prefab
	local prefab = prefabFolder:FindFirstChild(structureType)
	if not prefab then
		return false, "Prefab no encontrado"
	end
	-- Clonar y posicionar
	local modelClone = prefab:Clone()
	modelClone.Name = structureId
	-- Asegurarse de tener PrimaryPart
	local primary = modelClone.PrimaryPart or modelClone:FindFirstChildWhichIsA("BasePart")
	if primary then
		modelClone:SetPrimaryPartCFrame(CFrame.new(position))
	else
		-- Si no hay PrimaryPart, posicionar todo el modelo
		for _, part in ipairs(modelClone:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CFrame = CFrame.new(position + Vector3.new(0, part.Size.Y/2, 0))
			end
		end
	end
	-- Parentear dentro de la base del jugador
	local baseModel = basesFolder:FindFirstChild("Base_" .. player.Name)
	if baseModel then
		modelClone.Parent = baseModel
	else
		modelClone.Parent = workspace
	end
	return true, structureId
end

print("[PlacementHandler] RemoteFunction PlaceStructure listo.")
