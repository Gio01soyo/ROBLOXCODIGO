-- File: ServerScriptService/src/Modules/ExplorerModule.lua
-- Responsabilidades:
--  - Generar islas flotantes procedurales (datos de reliquias, rarezas)
--  - Manejar mecánica de clics y bots de excavación offline
--  - Integrar EconomyModule para recompensar ArcaneCoins
-- API pública:
--    StartExploration(player, islandId)
--    CollectResource(player, nodeId)
--    CalculateOfflineYield(player, hours)

local DataStoreService   = game:GetService("DataStoreService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")

-- Requerir EconomyModule
local srcFolder      = game.ServerScriptService:WaitForChild("src")
local modulesFolder  = srcFolder:WaitForChild("Modules")
local EconomyModule  = require(modulesFolder:WaitForChild("EconomyModule"))

local explorerRemotes    = ReplicatedStorage:WaitForChild("ExplorerRemotes")
local StartExplorationRF = explorerRemotes:WaitForChild("StartExploration")
local CollectResourceRF  = explorerRemotes:WaitForChild("CollectResource")
local OfflineYieldRF     = explorerRemotes:WaitForChild("CalculateOfflineYield")
local ResourceCollectedRE = explorerRemotes:WaitForChild("ResourceCollected")

local ExplorerModule = {}
ExplorerModule.__index = ExplorerModule

-- Evento OnIslandDiscovered
local OnIslandDiscovered = Instance.new("BindableEvent")
OnIslandDiscovered.Name   = "OnIslandDiscovered"
OnIslandDiscovered.Parent = ReplicatedStorage
ExplorerModule.OnIslandDiscovered = OnIslandDiscovered

-- Definiciones de rarezas
local RarityDefs = {
	["Comun"] = { dropRate = 50, minReward = 5,   maxReward = 10,  color = BrickColor.new("Medium stone grey"), icon = "Icon_Comun" },
	["PocoComun"] = { dropRate = 30, minReward = 11,  maxReward = 25,  color = BrickColor.new("Bright green"),   icon = "Icon_PocoComun" },
	["Rara"] = { dropRate = 15, minReward = 26,  maxReward = 60,  color = BrickColor.new("Bright blue"),    icon = "Icon_Rara" },
	["Épica"] = { dropRate = 5,  minReward = 61,  maxReward = 150, color = BrickColor.new("Bright violet"), icon = "Icon_Epica" },
}

-- Datos de islas y exploraciones por jugador
globalIslandDefs   = {}
local playerExplorations = {}

-- Selecciona una rareza basado en drop rates
local function pickRarity()
	local roll = math.random(1, 100)
	local cumulative = 0
	for name, def in pairs(RarityDefs) do
		cumulative = cumulative + def.dropRate
		if roll <= cumulative then
			return name
		end
	end
	return "Comun"
end

-- Genera definiciones de islas (datos)
function ExplorerModule:GenerateIslands(numIslands)
	globalIslandDefs = {}
	for i = 1, numIslands do
		local id = "isla" .. i
		local nodes = {}
		for j = 1, 5 do
			local rarity = pickRarity()
			table.insert(nodes, {
				nodeId   = id .. "_nodo" .. j,
				type     = "ReliquiaBasica",
				rarity   = rarity,
				color    = RarityDefs[rarity].color,
				icon     = RarityDefs[rarity].icon,
				depleted = false,
			})
		end
		table.insert(globalIslandDefs, { id = id, nodes = nodes })
		ExplorerModule.OnIslandDiscovered:Fire({}, id)
	end
	return globalIslandDefs
end

-- Inicia exploración: limpia previa, spawnea isla y teleporta al jugador
function ExplorerModule:StartExploration(player, islandId)
	-- buscar definición
	local def
	for _, isl in ipairs(globalIslandDefs) do
		if isl.id == islandId then def = isl; break end
	end
	if not def then
		warn("[ExplorerModule] Isla no encontrada: " .. islandId)
		return
	end

	-- limpiar exploración previa
	if playerExplorations[player.UserId] then
		playerExplorations[player.UserId].islandModel:Destroy()
	end

	-- crear modelo de isla
	local model = Instance.new("Model")
	model.Name   = player.Name .. "_" .. islandId
	model.Parent = workspace

	local basePos = Vector3.new(0, 50, 0)
	local origin  = basePos + Vector3.new((player.UserId % 10) * 60, 0, 0)

	-- teleport
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = CFrame.new(origin + Vector3.new(0, 5, 0))
	else
		player.CharacterAdded:Connect(function(char)
			local hrp = char:WaitForChild("HumanoidRootPart")
			hrp.CFrame = CFrame.new(origin + Vector3.new(0, 5, 0))
		end)
	end

	-- suelo
	local ground = Instance.new("Part")
	ground.Name         = "Ground"
	ground.Size         = Vector3.new(50, 1, 50)
	ground.Anchored     = true
	ground.Position     = origin + Vector3.new(0, -1, 0)
	ground.Parent       = model

	-- nodos con ClickDetector
	for idx, node in ipairs(def.nodes) do
		local rock = Instance.new("Part")
		rock.Name     = node.nodeId
		rock.Shape    = Enum.PartType.Ball
		rock.Size     = Vector3.new(4, 4, 4)
		rock.Anchored = true
		local angle  = (idx - 1) * (2 * math.pi / #def.nodes)
		local radius = 15
		rock.Position = origin + Vector3.new(math.cos(angle) * radius, 2, math.sin(angle) * radius)
		rock.BrickColor = node.color
		rock.Parent   = model

		local clickDet = Instance.new("ClickDetector")
		clickDet.MaxActivationDistance = 32
		clickDet.Parent = rock
		clickDet.MouseClick:Connect(function(clicker)
			if clicker == player then
				ExplorerModule:CollectResource(player, node.nodeId)
				ResourceCollectedRE:FireClient(clicker)
			end
		end)
	end

	playerExplorations[player.UserId] = { islandModel = model, definitions = def }
end

-- Marca nodo como recolectado y recompensa con ArcaneCoins
function ExplorerModule:CollectResource(player, nodeId)
	local rec = playerExplorations[player.UserId]
	if not rec then return end
	for _, node in ipairs(rec.definitions.nodes) do
		if node.nodeId == nodeId and not node.depleted then
			node.depleted = true
			-- Recompensa aleatoria según rareza
			local def = RarityDefs[node.rarity]
			local reward = math.random(def.minReward, def.maxReward)
			EconomyModule:AddCurrency(player, "ArcaneCoins", reward)
			return
		end
	end
end

-- Calcula rendimiento offline (remains unchanged)
function ExplorerModule:CalculateOfflineYield(player, hours)
	local h = math.min(12, math.max(0, hours))
	local ok, data = pcall(function()
		return DataStoreService:GetDataStore("ExplorerState"):GetAsync(player.UserId .. ":BotCount")
	end)
	local botCount = (ok and data) or 0
	return botCount * 5 * h
end

-- Conexión de remotes en servidor
if RunService:IsServer() then
	StartExplorationRF.OnServerInvoke = function(p, i) ExplorerModule:StartExploration(p, i) end
	CollectResourceRF.OnServerInvoke  = function(p, n) return ExplorerModule:CollectResource(p, n) end
	OfflineYieldRF.OnServerInvoke     = function(p, h) return ExplorerModule:CalculateOfflineYield(p, h) end
end

return ExplorerModule
