-- File: StarterPlayerScripts/ExplorerHUD.lua
-- Responsable de mostrar HUD unificado para monedas y construcción/mejora

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Remotes económicos
local econRemotes = ReplicatedStorage:WaitForChild("EconomyRemotes")
local RequestBalanceRF = econRemotes:WaitForChild("RequestBalance")
local BalanceChangedRE = econRemotes:WaitForChild("BalanceChanged")

-- Remotes tycoon/builder
local tycoonRemotes = ReplicatedStorage:WaitForChild("TycoonRemotes")
local BuildStructureRF = tycoonRemotes:WaitForChild("BuildStructure")
local UpgradeStructureRF = tycoonRemotes:WaitForChild("UpgradeStructure")

-- Evento local para actualizar UI
local BalanceChanged = Instance.new("BindableEvent")

-- UI elements
local screenGui, balanceLabel, buildButton, upgradeButton

-- Función para actualizar el texto del balance
local function updateBalanceText(newAmount)
	if balanceLabel then
		balanceLabel.Text = string.format("Arcane Coins: %d", newAmount)
	end
end

-- Escuchar evento del servidor para cambios de balance
BalanceChangedRE.OnClientEvent:Connect(function(currencyType, newAmount)
	if currencyType == "ArcaneCoins" then
		BalanceChanged:Fire(newAmount)
	end
end)

-- Inicializar HUD
local function setupHUD()
	if not player.PlayerGui then return end
	if player.PlayerGui:FindFirstChild("ExplorerHUD") then return end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ExplorerHUD"
	screenGui.ResetOnSpawn = true
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player.PlayerGui

	-- Restaurar comportamiento del mouse
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 250, 0, 70)
	frame.Position = UDim2.new(0.5, -125, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.Parent = screenGui

	balanceLabel = Instance.new("TextLabel")
	balanceLabel.Size = UDim2.new(1, 0, 0, 30)
	balanceLabel.Position = UDim2.new(0, 0, 0, 0)
	balanceLabel.TextScaled = true
	balanceLabel.BackgroundTransparency = 1
	balanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	balanceLabel.Text = "Arcane Coins: 0"
	balanceLabel.Parent = frame

	buildButton = Instance.new("TextButton")
	buildButton.Size = UDim2.new(0.5, -5, 0, 30)
	buildButton.Position = UDim2.new(0, 0, 0, 35)
	buildButton.Text = "Construir"
	buildButton.Parent = frame

	upgradeButton = Instance.new("TextButton")
	upgradeButton.Size = UDim2.new(0.5, -5, 0, 30)
	upgradeButton.Position = UDim2.new(0.5, 5, 0, 35)
	upgradeButton.Text = "Mejorar"
	upgradeButton.Parent = frame

	-- Conectar actualización de balance
	BalanceChanged.Event:Connect(updateBalanceText)

	-- Obtener balance inicial
	spawn(function()
		local initial = RequestBalanceRF:InvokeServer("ArcaneCoins")
		updateBalanceText(initial)
	end)

	-- Construir: solicitar al servidor y colocar prefab al confirmar
	buildButton.MouseButton1Click:Connect(function()
		-- Aquí invocarías un selector de posición y luego:
		-- local success, id = BuildStructureRF:InvokeServer("Taller")
		-- Si success, clonar prefab en esa posición
	end)

	-- Mejorar: similar, requiere apuntar a una estructura existente
	upgradeButton.MouseButton1Click:Connect(function()
		-- local targetId = determinar ID de la construcción señalada
		-- local newLevel, err = UpgradeStructureRF:InvokeServer(targetId)
		-- Mostrar resultado
	end)
end

player.CharacterAdded:Connect(setupHUD)
setupHUD()
