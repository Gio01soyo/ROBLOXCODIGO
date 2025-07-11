local srcFolder      = game.ServerScriptService:WaitForChild("src")
local modulesFolder  = srcFolder:WaitForChild("Modules")
local ExplorerModule = require(modulesFolder:WaitForChild("ExplorerModule"))

-- 1) Generamos las islas (datos) solo UNA vez
ExplorerModule:GenerateIslands(3)
print("[ExplorerInit] Definidas 3 islas procedurales")

-- 2) Cada vez que un jugador se conecta, spawneamos su isla
game.Players.PlayerAdded:Connect(function(player)
	-- Aquí puedes elegir isla1, isla2, isla3 o una aleatoria:
	ExplorerModule:StartExploration(player, "isla1")
end)
