-- ██████████████████████████████████████████████████████████████
-- ██                                                          ██
-- ██           GamerXsan FISHIT V2.0 - FIXED TELEPORT         ██
-- ██                 ENHANCED TELEPORTATION                    ██
-- ██                                                          ██
-- ██████████████████████████████████████████████████████████████

-- Configuration
local CONFIG = {
    GUI_NAME = "GamerXsan_Fixed", 
    GUI_TITLE = "Mod GamerXsan - Enhanced Teleport",
    HOTKEY = Enum.KeyCode.F9,
}

local success, error = pcall(function()

-- Destroy existing GUI
if game.Players.LocalPlayer.PlayerGui:FindFirstChild(CONFIG.GUI_NAME) then
    game.Players.LocalPlayer.PlayerGui[CONFIG.GUI_NAME]:Destroy()
end

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local connections = {}

-- UI References (Global scope)
local PlayerInput
local PlayerCountLabel
local ListOfTpPlayer
local MainGUI

-- ===================================================================
--                    ENHANCED TELEPORTATION FUNCTIONS
-- ===================================================================

-- Enhanced Safe Teleport Function
local function safeTeleport(targetPosition, targetName)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        print("❌ Cannot teleport: Character not found")
        return false
    end
    
    if not targetPosition or typeof(targetPosition) ~= "Vector3" then
        print("❌ Cannot teleport: Invalid target position")
        return false
    end
    
    -- Check distance to prevent void teleports
    local currentPos = player.Character.HumanoidRootPart.Position
    local distance = (targetPosition - currentPos).Magnitude
    
    if distance > 10000 then
        print("❌ Cannot teleport: Target too far (" .. math.floor(distance) .. " studs)")
        return false
    end
    
    -- Smooth teleport for long distances
    if distance > 1000 then
        print("🚀 Long distance teleport: " .. math.floor(distance) .. " studs")
        local steps = math.ceil(distance / 500)
        local stepVector = (targetPosition - currentPos) / steps
        
        for i = 1, steps do
            wait(0.1)
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                return false
            end
            local intermediatePos = currentPos + (stepVector * i)
            player.Character.HumanoidRootPart.CFrame = CFrame.new(intermediatePos)
        end
    else
        -- Direct teleport for short distances
        player.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
    end
    
    print("✅ Successfully teleported to " .. (targetName or "target location"))
    return true
end

-- Enhanced Player Detection Function (3-Tier System)
local function findPlayer(targetPlayerName)
    if not targetPlayerName or targetPlayerName == "" then
        return nil
    end
    
    local lowerTargetName = string.lower(targetPlayerName)
    local foundPlayer = nil
    local foundCharacter = nil
    
    -- Tier 1: Players Service (Standard method)
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            local playerName = string.lower(targetPlayer.Name)
            if playerName == lowerTargetName or playerName:find(lowerTargetName, 1, true) then
                if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    return targetPlayer, targetPlayer.Character
                else
                    foundPlayer = targetPlayer
                end
            end
        end
    end
    
    -- Tier 2: Workspace Models
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name ~= player.Name then
            local objName = string.lower(obj.Name)
            if objName == lowerTargetName or objName:find(lowerTargetName, 1, true) then
                if obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
                    return nil, obj
                end
            end
        end
    end
    
    -- Tier 3: Characters Folder
    local charFolder = workspace:FindFirstChild("Characters") or workspace:FindFirstChild("characters")
    if charFolder then
        for _, charModel in pairs(charFolder:GetChildren()) do
            if charModel:IsA("Model") and charModel.Name ~= player.Name then
                local charName = string.lower(charModel.Name)
                if charName == lowerTargetName or charName:find(lowerTargetName, 1, true) then
                    if charModel:FindFirstChild("HumanoidRootPart") then
                        return nil, charModel
                    end
                end
            end
        end
    end
    
    return foundPlayer, foundCharacter
end

-- Enhanced Teleport to Player Function
local function teleportToPlayer(targetPlayerName)
    if not targetPlayerName or targetPlayerName == "" then
        print("❌ Please enter a player name")
        return
    end
    
    local foundPlayer, foundCharacter = findPlayer(targetPlayerName)
    
    if foundCharacter and foundCharacter:FindFirstChild("HumanoidRootPart") then
        local targetPos = foundCharacter.HumanoidRootPart.Position
        local safeCFrame = targetPos + Vector3.new(0, 3, 0)
        
        if safeTeleport(safeCFrame, foundCharacter.Name) then
            print("🎯 Teleported to " .. foundCharacter.Name)
        end
    elseif foundPlayer then
        print("❌ Player " .. foundPlayer.Name .. " found but character not loaded")
    else
        print("❌ Player '" .. targetPlayerName .. "' not found")
        print("💡 Try using partial names (e.g., 'abc' for 'abcdef123')")
    end
end

-- Enhanced Player List Updater
local function updatePlayerList()
    if not ListOfTpPlayer then return end
    
    -- Clear existing buttons
    for _, child in pairs(ListOfTpPlayer:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Add list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = ListOfTpPlayer
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Padding = UDim.new(0, 2)
    
    -- Get all players from multiple sources
    local allPlayers = {}
    local playerCount = 0
    
    -- Source 1: Players Service
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            local hasCharacter = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            table.insert(allPlayers, {
                name = targetPlayer.Name,
                character = targetPlayer.Character,
                hasHRP = hasCharacter,
                source = "Players",
                player = targetPlayer
            })
            playerCount = playerCount + 1
        end
    end
    
    -- Source 2: Workspace Models
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name ~= player.Name and obj:FindFirstChild("HumanoidRootPart") then
            local alreadyExists = false
            for _, existingPlayer in pairs(allPlayers) do
                if existingPlayer.name == obj.Name then
                    alreadyExists = true
                    break
                end
            end
            
            if not alreadyExists and obj:FindFirstChild("Humanoid") then
                table.insert(allPlayers, {
                    name = obj.Name,
                    character = obj,
                    hasHRP = true,
                    source = "Workspace",
                    player = nil
                })
                playerCount = playerCount + 1
            end
        end
    end
    
    -- Source 3: Characters Folder
    local charFolder = workspace:FindFirstChild("Characters") or workspace:FindFirstChild("characters")
    if charFolder then
        for _, charModel in pairs(charFolder:GetChildren()) do
            if charModel:IsA("Model") and charModel.Name ~= player.Name and charModel:FindFirstChild("HumanoidRootPart") then
                local alreadyExists = false
                for _, existingPlayer in pairs(allPlayers) do
                    if existingPlayer.name == charModel.Name then
                        alreadyExists = true
                        break
                    end
                end
                
                if not alreadyExists then
                    table.insert(allPlayers, {
                        name = charModel.Name,
                        character = charModel,
                        hasHRP = true,
                        source = "Characters",
                        player = nil
                    })
                    playerCount = playerCount + 1
                end
            end
        end
    end
    
    -- Update player count
    if PlayerCountLabel then
        PlayerCountLabel.Text = "Players Online: " .. playerCount
    end
    
    -- Create buttons for all detected players
    for _, playerData in pairs(allPlayers) do
        local btn = Instance.new("TextButton")
        btn.Name = playerData.name
        btn.Parent = ListOfTpPlayer
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        
        -- Color coding
        if playerData.hasHRP then
            btn.BackgroundColor3 = Color3.fromRGB(0, 120, 0) -- Green for ready
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(120, 60, 0) -- Orange for not ready
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        -- Add source indicator
        local sourceIcon = ""
        if playerData.source == "Players" then
            sourceIcon = "👤"
        elseif playerData.source == "Workspace" then
            sourceIcon = "🌍"
        elseif playerData.source == "Characters" then
            sourceIcon = "📁"
        end
        
        btn.Text = sourceIcon .. " " .. playerData.name .. (playerData.hasHRP and " ✅" or " ❌")
        
        -- Add corner rounding
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        -- Button click event
        connections[#connections + 1] = btn.MouseButton1Click:Connect(function()
            if playerData.hasHRP and playerData.character then
                local targetPos = playerData.character.HumanoidRootPart.Position
                local safeCFrame = targetPos + Vector3.new(0, 3, 0)
                safeTeleport(safeCFrame, playerData.name)
                
                -- Auto-fill the input box
                if PlayerInput then
                    PlayerInput.Text = playerData.name
                end
            else
                print("❌ Cannot teleport to " .. playerData.name .. " - character not ready")
            end
        end)
    end
end

-- ===================================================================
--                           GUI CREATION
-- ===================================================================

local function createGUI()
    -- Create main ScreenGui
    MainGUI = Instance.new("ScreenGui")
    MainGUI.Name = CONFIG.GUI_NAME
    MainGUI.Parent = player:WaitForChild("PlayerGui")
    MainGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = MainGUI
    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
    MainFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = MainFrame

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.Size = UDim2.new(1, 0, 0.1, 0)
    Title.Font = Enum.Font.SourceSansBold
    Title.Text = CONFIG.GUI_TITLE
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = MainFrame
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 34)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Position = UDim2.new(0.92, 0, 0.02, 0)
    CloseBtn.Size = UDim2.new(0.06, 0, 0.06, 0)
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextScaled = true
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = CloseBtn

    -- Player Input
    PlayerInput = Instance.new("TextBox")
    PlayerInput.Parent = MainFrame
    PlayerInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    PlayerInput.BorderSizePixel = 0
    PlayerInput.Position = UDim2.new(0.05, 0, 0.15, 0)
    PlayerInput.Size = UDim2.new(0.6, 0, 0.08, 0)
    PlayerInput.Font = Enum.Font.SourceSansBold
    PlayerInput.PlaceholderText = "Enter player name..."
    PlayerInput.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
    PlayerInput.Text = ""
    PlayerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerInput.TextScaled = true
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = PlayerInput

    -- Teleport Button
    local TeleportBtn = Instance.new("TextButton")
    TeleportBtn.Parent = MainFrame
    TeleportBtn.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    TeleportBtn.BorderSizePixel = 0
    TeleportBtn.Position = UDim2.new(0.7, 0, 0.15, 0)
    TeleportBtn.Size = UDim2.new(0.25, 0, 0.08, 0)
    TeleportBtn.Font = Enum.Font.SourceSansBold
    TeleportBtn.Text = "TELEPORT"
    TeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TeleportBtn.TextScaled = true
    
    local teleportCorner = Instance.new("UICorner")
    teleportCorner.CornerRadius = UDim.new(0, 6)
    teleportCorner.Parent = TeleportBtn

    -- Player List
    ListOfTpPlayer = Instance.new("ScrollingFrame")
    ListOfTpPlayer.Parent = MainFrame
    ListOfTpPlayer.Active = true
    ListOfTpPlayer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    ListOfTpPlayer.BorderSizePixel = 0
    ListOfTpPlayer.Position = UDim2.new(0.05, 0, 0.28, 0)
    ListOfTpPlayer.Size = UDim2.new(0.9, 0, 0.6, 0)
    ListOfTpPlayer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ListOfTpPlayer.ScrollBarThickness = 8
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = ListOfTpPlayer

    -- Player Count Label
    PlayerCountLabel = Instance.new("TextLabel")
    PlayerCountLabel.Parent = MainFrame
    PlayerCountLabel.BackgroundTransparency = 1
    PlayerCountLabel.Position = UDim2.new(0.05, 0, 0.9, 0)
    PlayerCountLabel.Size = UDim2.new(0.9, 0, 0.08, 0)
    PlayerCountLabel.Font = Enum.Font.SourceSansBold
    PlayerCountLabel.Text = "Players Online: 0"
    PlayerCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerCountLabel.TextScaled = true
    PlayerCountLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Event Handlers
    connections[#connections + 1] = CloseBtn.MouseButton1Click:Connect(function()
        MainGUI:Destroy()
        for _, connection in pairs(connections) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
    end)

    connections[#connections + 1] = TeleportBtn.MouseButton1Click:Connect(function()
        local targetName = PlayerInput.Text:gsub("^%s*(.-)%s*$", "%1")
        teleportToPlayer(targetName)
    end)

    connections[#connections + 1] = PlayerInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local targetName = PlayerInput.Text:gsub("^%s*(.-)%s*$", "%1")
            teleportToPlayer(targetName)
        end
    end)

    -- Real-time highlighting
    connections[#connections + 1] = PlayerInput:GetPropertyChangedSignal("Text"):Connect(function()
        local inputText = string.lower(PlayerInput.Text)
        if inputText ~= "" then
            for _, child in pairs(ListOfTpPlayer:GetChildren()) do
                if child:IsA("TextButton") then
                    local playerName = string.lower(child.Name)
                    if playerName:find(inputText, 1, true) then
                        child.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
                        child.BorderSizePixel = 2
                        child.BorderColor3 = Color3.fromRGB(255, 255, 255)
                    else
                        if child.Text:find("✅") then
                            child.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
                        else
                            child.BackgroundColor3 = Color3.fromRGB(120, 60, 0)
                        end
                        child.BorderSizePixel = 0
                    end
                end
            end
        else
            for _, child in pairs(ListOfTpPlayer:GetChildren()) do
                if child:IsA("TextButton") then
                    if child.Text:find("✅") then
                        child.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
                    else
                        child.BackgroundColor3 = Color3.fromRGB(120, 60, 0)
                    end
                    child.BorderSizePixel = 0
                end
            end
        end
    end)

    -- Auto-update events
    connections[#connections + 1] = Players.PlayerAdded:Connect(updatePlayerList)
    connections[#connections + 1] = Players.PlayerRemoving:Connect(updatePlayerList)
    
    -- Periodic update
    local lastPlayerUpdate = 0
    connections[#connections + 1] = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastPlayerUpdate >= 3 then
            lastPlayerUpdate = currentTime
            updatePlayerList()
        end
    end)
    
    -- Character spawn detection
    connections[#connections + 1] = Players.PlayerAdded:Connect(function(newPlayer)
        if newPlayer ~= player then
            connections[#connections + 1] = newPlayer.CharacterAdded:Connect(function()
                wait(1)
                updatePlayerList()
            end)
        end
    end)
    
    -- Monitor existing players
    for _, existingPlayer in pairs(Players:GetPlayers()) do
        if existingPlayer ~= player then
            connections[#connections + 1] = existingPlayer.CharacterAdded:Connect(function()
                wait(1)
                updatePlayerList()
            end)
        end
    end

    -- Initial update
    updatePlayerList()
    
    print("✅ Enhanced Teleportation GUI loaded successfully!")
    print("🎯 Features: Auto-updating player list, 3-tier detection, smart search")
    print("💡 Usage: Type player name and press Enter or click TELEPORT")
end

-- Initialize
createGUI()

end) -- End of main pcall

if not success then
    warn("❌ Enhanced Teleport GUI failed to load: " .. tostring(error))
else
    print("🚀 Enhanced Teleport GUI loaded successfully!")
end
