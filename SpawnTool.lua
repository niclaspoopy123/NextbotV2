-- ========================================================================
-- [[ CLIENT-SIDE SPAWN TOOL ]]
-- Places this in StarterPlayer > StarterPlayerScripts or StarterGui
-- When equipped, left-click to set the spawn position and spawn the nextbot
-- ========================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local SPAWN_TOOL_CONFIG = {
    ENABLED = true,
    CLICK_KEY = Enum.UserInputType.MouseButton1,
    SPAWN_HEIGHT_OFFSET = 5,  -- How high above click position the bot spawns
}

local spawnToolActive = false
local spawnMarker = nil

-- ========================================================================
-- [[ UI HELPERS ]]
-- ========================================================================

local function createSpawnMarker(position)
    if spawnMarker then
        spawnMarker:Destroy()
    end
    
    spawnMarker = Instance.new("Part")
    spawnMarker.Name = "SpawnMarker"
    spawnMarker.Shape = Enum.PartType.Ball
    spawnMarker.Size = Vector3.new(2, 2, 2)
    spawnMarker.BrickColor = BrickColor.new("Bright red")
    spawnMarker.Material = Enum.Material.Neon
    spawnMarker.CanCollide = false
    spawnMarker.CFrame = CFrame.new(position + Vector3.new(0, SPAWN_TOOL_CONFIG.SPAWN_HEIGHT_OFFSET, 0))
    spawnMarker.Parent = workspace
    
    -- Add a light for visibility
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range = 20
    light.Color = Color3.fromRGB(255, 0, 0)
    light.Parent = spawnMarker
    
    return spawnMarker
end

local function clearSpawnMarker()
    if spawnMarker then
        spawnMarker:Destroy()
        spawnMarker = nil
    end
end

-- ========================================================================
-- [[ SPAWN REQUEST ]]
-- ========================================================================

local function requestSpawnAtPosition(worldPosition)
    -- Raycast downward to find the ground
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {player.Character}
    rayParams.IgnoreWater = false
    
    local spawnY = worldPosition.Y
    local rayResult = workspace:Raycast(
        worldPosition + Vector3.new(0, 50, 0),
        Vector3.new(0, -100, 0),
        rayParams
    )
    
    if rayResult then
        spawnY = rayResult.Position.Y + SPAWN_TOOL_CONFIG.SPAWN_HEIGHT_OFFSET
    end
    
    local finalSpawnPos = Vector3.new(worldPosition.X, spawnY, worldPosition.Z)
    
    -- Show marker at spawn position
    createSpawnMarker(worldPosition)
    
    -- Fire remote or call server to spawn the nextbot
    -- If you have a RemoteEvent for spawning, use it here:
    -- local spawnRemote = game.ReplicatedStorage:WaitForChild("SpawnNextbotRemote")
    -- spawnRemote:FireServer(finalSpawnPos)
    
    print("NextBot spawn requested at position:", finalSpawnPos)
    
    -- Temporary visual feedback
    game:GetService("Debris"):AddItem(spawnMarker, 3)
    spawnMarker = nil
end

-- ========================================================================
-- [[ INPUT HANDLING ]]
-- ========================================================================

local function onMouseClick()
    if not SPAWN_TOOL_CONFIG.ENABLED or not spawnToolActive then
        return
    end
    
    local targetPosition = mouse.Hit.Position
    
    if targetPosition then
        requestSpawnAtPosition(targetPosition)
    end
end

local function activateSpawnTool()
    spawnToolActive = true
    mouse.Icon = "rbxasset://textures/Cursors/MouseLockedCursor.png"
    print("[SpawnTool] Spawn tool activated - click to spawn nextbot!")
    
    -- Show initial instructions
    if player:FindFirstChild("PlayerGui") then
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SpawnToolGui"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = player:WaitForChild("PlayerGui")
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "SpawnToolLabel"
        textLabel.Size = UDim2.new(0, 300, 0, 60)
        textLabel.Position = UDim2.new(0.5, -150, 0, 20)
        textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.BackgroundTransparency = 0.5
        textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        textLabel.TextSize = 16
        textLabel.Font = Enum.Font.GothamBold
        textLabel.Text = "SPAWN TOOL ACTIVE\nClick to spawn nextbot"
        textLabel.Parent = screenGui
        
        game:GetService("Debris"):AddItem(screenGui, 10)
    end
end

local function deactivateSpawnTool()
    spawnToolActive = false
    clearSpawnMarker()
    mouse.Icon = ""
    print("[SpawnTool] Spawn tool deactivated")
end

-- ========================================================================
-- [[ EVENT CONNECTIONS ]]
-- ========================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == SPAWN_TOOL_CONFIG.CLICK_KEY then
        onMouseClick()
    end
end)

-- Activate on spawn or via chat command
local function setupSpawnCommand()
    local success, err = pcall(function()
        -- Alternative: Activate via chat command (e.g., /spawn)
        -- You can implement this if you have a chat system
        activateSpawnTool()
    end)
end

-- Start the spawn tool when the script loads
setupSpawnCommand()

-- Cleanup on character respawn
player.CharacterAdded:Connect(function()
    deactivateSpawnTool()
    clearSpawnMarker()
end)

print("[SpawnTool] Loaded successfully - NextBot spawn tool ready!")
