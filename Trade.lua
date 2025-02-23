-- Blox Fruits Trade Freeze and Auto-Accept (Delta Executor)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TradingService = game:GetService("ReplicatedStorage"):WaitForChild("TradingService")
local TradeRemote = TradingService:WaitForChild("TradeRemote")

local freezeEnabled = false
local autoAcceptEnabled = false

-- Freeze Function
local function freezePlayer(player)
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        local originalCFrame = rootPart.CFrame
        local originalVelocity = rootPart.Velocity
        local originalAngularVelocity = rootPart.AngularVelocity

        local connection1 = rootPart:GetPropertyChangedSignal("CFrame"):Connect(function()
            rootPart.CFrame = originalCFrame
        end)
        local connection2 = rootPart:GetPropertyChangedSignal("Velocity"):Connect(function()
            rootPart.Velocity = originalVelocity
        end)
        local connection3 = rootPart:GetPropertyChangedSignal("AngularVelocity"):Connect(function()
            rootPart.AngularVelocity = originalAngularVelocity
        end)

        return {
            connections = {connection1,connection2,connection3},
            originalCFrame = originalCFrame,
            originalVelocity = originalVelocity,
            originalAngularVelocity = originalAngularVelocity,
        }
    end
    return nil;
end

local frozenPlayers = {}

local function unfreezePlayer(player, freezeData)
    if freezeData then
        for _, connection in pairs(freezeData.connections) do
            connection:Disconnect()
        end
    end
end

local function handleTradeRequests()
    TradingService.TradeRequestReceived.OnClientEvent:Connect(function(requester)
        if autoAcceptEnabled then
            TradeRemote:FireServer("AcceptTrade", requester)
        end
        if freezeEnabled then
            frozenPlayers[requester] = freezePlayer(requester)
        end
    end)

    TradingService.TradeCancelled.OnClientEvent:Connect(function(canceler)
        if frozenPlayers[canceler] then
            unfreezePlayer(canceler, frozenPlayers[canceler])
            frozenPlayers[canceler] = nil
        end
    end)

    TradingService.TradeCompleted.OnClientEvent:Connect(function(accepter, requester)
        if frozenPlayers[requester] then
            unfreezePlayer(requester, frozenPlayers[requester])
            frozenPlayers[requester] = nil
        end
        if frozenPlayers[accepter] then
            unfreezePlayer(accepter, frozenPlayers[accepter])
            frozenPlayers[accepter] = nil;
        end
    end)
end

-- UI (Basic Toggle Buttons)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TradeControls"
ScreenGui.Parent = LocalPlayer.PlayerGui

local FreezeButton = Instance.new("TextButton")
FreezeButton.Name = "FreezeTradeButton"
FreezeButton.Parent = ScreenGui
FreezeButton.Position = UDim2.new(0.05, 0, 0.05, 0)
FreezeButton.Size = UDim2.new(0, 150, 0, 30)
FreezeButton.Text = "Freeze Trade: Off"
FreezeButton.BackgroundColor3 = Color3.new(1, 0, 0)
FreezeButton.MouseButton1Click:Connect(function()
    freezeEnabled = not freezeEnabled
    if freezeEnabled then
        FreezeButton.Text = "Freeze Trade: On"
        FreezeButton.BackgroundColor3 = Color3.new(0, 1, 0)
    else
        FreezeButton.Text = "Freeze Trade: Off"
        FreezeButton.BackgroundColor3 = Color3.new(1, 0, 0)
        for player, freezeData in pairs(frozenPlayers) do
            unfreezePlayer(player, freezeData)
        end
        frozenPlayers = {}
    end
end)

local AutoAcceptButton = Instance.new("TextButton")
AutoAcceptButton.Name = "AutoAcceptButton"
AutoAcceptButton.Parent = ScreenGui
AutoAcceptButton.Position = UDim2.new(0.05, 0, 0.15, 0)
AutoAcceptButton.Size = UDim2.new(0, 150, 0, 30)
AutoAcceptButton.Text = "Auto Accept: Off"
AutoAcceptButton.BackgroundColor3 = Color3.new(1, 0, 0)
AutoAcceptButton.MouseButton1Click:Connect(function()
    autoAcceptEnabled = not autoAcceptEnabled
    if autoAcceptEnabled then
        AutoAcceptButton.Text = "Auto Accept: On"
        AutoAcceptButton.BackgroundColor3 = Color3.new(0, 1, 0)
    else
        AutoAcceptButton.Text = "Auto Accept: Off"
        AutoAcceptButton.BackgroundColor3 = Color3.new(1, 0, 0)
    end
end)

handleTradeRequests()