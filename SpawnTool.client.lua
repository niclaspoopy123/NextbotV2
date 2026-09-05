-- [[ NEXTBOT SPAWN TOOL (client) ]]
-- Left-click anywhere in the world to move the nextbot to that spot.
-- Paste this entire file into a LocalScript named "SpawnTool" parented
-- inside the Main server script (it is cloned into each player's
-- PlayerScripts at runtime).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local spawnRemote = ReplicatedStorage:WaitForChild("SpawnNextbotRemote")

local SPAWN_HEIGHT_OFFSET = 5   -- how far above the ground the bot spawns

local spawnToolActive = false
local spawnMarker = nil
local statusLabel = nil

-- Red neon sphere marking the clicked spawn location.
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
    spawnMarker.Anchored = true
    spawnMarker.CanCollide = false
    spawnMarker.CFrame = CFrame.new(position)
    spawnMarker.Parent = workspace

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

-- "SPAWN TOOL ACTIVE" indicator at the top of the screen.
local function createSpawnToolGui()
    local playerGui = player:WaitForChild("PlayerGui")
    local screenGui = playerGui:FindFirstChild("SpawnToolGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SpawnToolGui"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = playerGui

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

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = textLabel
    end
    return screenGui.SpawnToolLabel
end

-- Left-click: mark the spot, find the ground, ask the server to spawn there.
local function onSpawnToolClick()
    if not spawnToolActive then
        return
    end

    local targetPosition = mouse.Hit and mouse.Hit.Position
    if not targetPosition then
        return
    end

    local marker = createSpawnMarker(targetPosition)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {player.Character, marker}
    rayParams.IgnoreWater = false

    local spawnY = targetPosition.Y + SPAWN_HEIGHT_OFFSET
    local rayResult = workspace:Raycast(targetPosition + Vector3.new(0, 50, 0), Vector3.new(0, -150, 0), rayParams)
    if rayResult then
        spawnY = rayResult.Position.Y + SPAWN_HEIGHT_OFFSET
    end

    local finalSpawnPos = Vector3.new(targetPosition.X, spawnY, targetPosition.Z)
    spawnRemote:FireServer(finalSpawnPos)
    print("[SpawnTool] NextBot spawn requested at:", finalSpawnPos)

    if statusLabel then
        statusLabel.Text = "SPAWN TOOL ACTIVE\nNextbot spawned!"
        task.delay(2, function()
            if statusLabel then
                statusLabel.Text = "SPAWN TOOL ACTIVE\nClick to spawn nextbot"
            end
        end)
    end

    Debris:AddItem(marker, 3)
    spawnMarker = nil
end

-- The tool is armed as soon as the game starts.
local function activateSpawnTool()
    if spawnToolActive then
        return
    end
    spawnToolActive = true
    statusLabel = createSpawnToolGui()
    mouse.Icon = "rbxasset://textures/Cursors/MouseLockedCursor.png"
    print("[SpawnTool] Spawn tool activated - click to spawn nextbot!")
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        onSpawnToolClick()
    end
end)

-- Re-arm the tool after a respawn so it stays usable for the whole session.
player.CharacterAdded:Connect(function()
    clearSpawnMarker()
    task.wait(0.5)
    activateSpawnTool()
end)

activateSpawnTool()
print("[SpawnTool] Loaded - NextBot spawn tool ready!")
