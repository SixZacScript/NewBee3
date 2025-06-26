-- GuiBotStatus.lua
local GuiService = {}
GuiService.__index = GuiService

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function GuiService.new()
    local self = setmetatable({}, GuiService)

    self.statusText = "Idle"
    self.gui = self:createGui()

    return self
end

function GuiService:createGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BotStatusGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "StatusFrame"
    frame.Size = UDim2.new(0, 200, 0, 50)
    frame.Position = UDim2.new(0, 10, 1, -60)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0, 1)
    frame.Parent = screenGui

    local label = Instance.new("TextLabel")
    label.Name = "StatusLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamSemibold
    label.Text = "Status: " .. self.statusText
    label.Parent = frame

    return screenGui
end

function GuiService:updateStatus(newStatus)
    self.statusText = newStatus
    local label = self.gui:FindFirstChild("StatusFrame"):FindFirstChild("StatusLabel")
    if label then
        label.Text = "Status: " .. newStatus
    end
end

return GuiService
