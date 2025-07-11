-- File: StarterPlayerScripts/BuildHandler.lua
-- Cliente: maneja selección de posición y construcción de estructuras

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Remotes
local tycoonRemotes = ReplicatedStorage:WaitForChild("TycoonRemotes")
local PlaceStructureRE = tycoonRemotes:WaitForChild("PlaceStructure")

-- Prefabs para ghost: validar existencia de la carpeta
local prefabFolder = ReplicatedStorage:FindFirstChild("Structures")
if not prefabFolder then
	warn("[BuildHandler] Carpeta 'Structures' no encontrada en ReplicatedStorage. Asegúrate de crearla y añadir tus prefabs.")
end

-- Variables de estado
local isPlacing = false
local selectedType = nil
local ghostModel = nil

-- Crear un modelo semitransparente de prefab
local function createGhost(prefab)
	if ghostModel then
		ghostModel:Destroy()
		ghostModel = nil
	end
	ghostModel = prefab:Clone()
	-- Asegurar PrimaryPart
	if not ghostModel.PrimaryPart then
		local firstPart = ghostModel:FindFirstChildWhichIsA("BasePart")
		ghostModel.PrimaryPart = firstPart
	end
	for _, part in ipairs(ghostModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0.5
			part.CanCollide = false
		end
	end
	ghostModel.PrimaryPart.CFrame = CFrame.new(0, 0, 0)
	ghostModel.Parent = workspace
end

-- Empezar colocación
local function startPlacement(structureType)
	if not prefabFolder then return end
	selectedType = structureType
	local prefab = prefabFolder:FindFirstChild(structureType)
	if not prefab then
		warn("[BuildHandler] Prefab no encontrado: " .. structureType)
		return
	end
	createGhost(prefab)
	isPlacing = true
	UserInputService.MouseIconEnabled = true
end

-- Finalizar colocación: invocar al servidor
local function confirmPlacement()
	if not isPlacing or not ghostModel then return end
	local position = ghostModel.PrimaryPart.Position
	-- Enviar evento al servidor
	PlaceStructureRE:FireServer(selectedType, position)
	-- Convertir ghost a construcción definitiva
	for _, part in ipairs(ghostModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0
			part.CanCollide = true
		end
	end
	ghostModel = nil
	isPlacing = false
end

-- Cancelar colocación
local function cancelPlacement()
	if ghostModel then
		ghostModel:Destroy()
		ghostModel = nil
	end
	isPlacing = false
end

-- Actualizar posición del ghost cada frame
task.spawn(function()
	RunService.RenderStepped:Connect(function()
		if isPlacing and ghostModel then
			local unitRay = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
			local ray = Ray.new(unitRay.Origin, unitRay.Direction * 1000)
			local _, hitPosition = workspace:FindPartOnRayWithIgnoreList(ray, {ghostModel})
			if hitPosition then
				ghostModel:SetPrimaryPartCFrame(CFrame.new(hitPosition))
			end
		end
	end)
end)

-- Entradas: click izquierdo confirma, ESC cancela
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if isPlacing then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			confirmPlacement()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			cancelPlacement()
		end
	end
end)

-- Conectar botón de construcción del HUD
local function connectHUD()
	local playerGui = player:WaitForChild("PlayerGui")
	local hud = playerGui:FindFirstChild("ExplorerHUD")
	if not hud then return end
	local frame = hud:FindFirstChildOfClass("Frame")
	if not frame then return end
	local buildButton = frame:FindFirstChild("Construir")
	if buildButton then
		buildButton.MouseButton1Click:Connect(function()
			startPlacement("Taller")
		end)
	end
end

player.CharacterAdded:Connect(connectHUD)
connectHUD()
