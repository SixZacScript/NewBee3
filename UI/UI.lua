
local UserInputService = game:GetService('UserInputService')
local FluentHelper = {}
FluentHelper.__index = FluentHelper


function FluentHelper.new()
    local self = setmetatable({}, FluentHelper)

    self:_initializeCore()
    self:_setupWindow()
    self:_createTabs()
    self:_initializeAllTabs()
    self:_setupAntiAFK()
    return self
end

function FluentHelper:_initializeCore()
    self.Fluent = shared.ModuleLoader:load("UI/WindowLua.lua")
    self.SaveManager = shared.ModuleLoader:load("UI/SaveManager.lua")
    self.InterfaceManager = shared.ModuleLoader:load("UI/InterfaceManager.lua")
    
    self.Tabs = {}
    self.tabConfigs = {
        {name = "main", title = "Main", icon = "grid"},
        {name = "player", title = "Player", icon = "user"},
        {name = "planter", title = "Planter", icon = "sprout"},
        {name = "Settings", title = "Setting", icon = "settings"}
    }
end
function FluentHelper:_setupWindow()
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local width, height, tabWidth
    local viewportSize = workspace.CurrentCamera.ViewportSize

    if isMobile then
        width = math.clamp(viewportSize.X * 0.9, 300, 500)
        height = math.clamp(viewportSize.Y * 0.5, 300, 400)
        tabWidth = 100
        self:createFloatingButton()
    else
        width = math.clamp(viewportSize.X * 0.6, 300, 600)
        height = math.clamp(viewportSize.Y * 0.6, 300, 500)
        tabWidth = 160
    end

    self.Window = self.Fluent:CreateWindow({
        Title = "Fluent",
        SubTitle = "by dawid",
        TabWidth = tabWidth,
        Size = UDim2.fromOffset(width, height),
        Acrylic = true,
        Theme = "MinimalDark",
        MinimizeKey = Enum.KeyCode.F
    })
end

function FluentHelper:_createTabs()
    for _, config in ipairs(self.tabConfigs) do
        self.Tabs[config.name] = self.Window:AddTab({
            Title = config.title,
            Icon = config.icon
        })
    end
end

function FluentHelper:_initializeAllTabs()
    for _, config in ipairs(self.tabConfigs) do
        local tabModule
        if config.name ~= "Settings" then
            tabModule = shared.ModuleLoader:load("UI/Tabs/" .. config.name .. ".lua")
        end

        if tabModule then
            self[config.name] = tabModule:load(self)
        else
            warn("[FluentHelper] Failed to load tab module: " .. config.name)
        end
    end

    self:_setupManagers()
end

function FluentHelper:_setupManagers()
    local settingsTab = self.Tabs.Settings
    self.hideDecorations = settingsTab:AddToggle("hideDecorations", {
        Title = "Hide Decorations",
        Default = true,
        Callback = function(val)
            shared.main.hideDecorations = val
            if val then
                shared.Helpers.Hide:Apply()
            else
                shared.Helpers.Hide:Restore()
            end
        end
    })

    self.SaveManager:SetLibrary(self.Fluent)
    self.InterfaceManager:SetLibrary(self.Fluent)
    self.InterfaceManager:SetFolder("FluentScriptHub")
    self.SaveManager:SetFolder("FluentScriptHub/specific-game")

    self.InterfaceManager:BuildInterfaceSection(settingsTab)
    self.SaveManager:BuildConfigSection(settingsTab)

    self.Window:SelectTab(1)
    self.SaveManager:LoadAutoloadConfig()


end

function FluentHelper:_setupAntiAFK()
    if self.afkConnection then 
        self.afkConnection:Disconnect() 
    end

    local virtualUser = game:GetService("VirtualUser")

    self.afkConnection = game.Players.LocalPlayer.Idled:Connect(function()
        virtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        virtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end
function FluentHelper:createFloatingButton()
    local button = Instance.new("TextButton")
    button.Name = "FloatingButton"
    button.Size = UDim2.fromOffset(80, 50)
    button.Position = UDim2.new(1, -20, 0, 20)
    button.AnchorPoint = Vector2.new(1, 0)

    
    -- Background styling
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    button.AutoButtonColor = false
    button.Text = "Open UI"
    button.TextColor3 = Color3.fromRGB(230, 230, 230)
    button.Font = Enum.Font.GothamSemibold
    button.TextScaled = true
    button.ZIndex = 999

    -- Rounded corners
    local uicorner = Instance.new("UICorner", button)
    uicorner.CornerRadius = UDim.new(0, 12)

    -- Hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end)

    button.Parent = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")

    local dragging = false
    local dragStart, startPos

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = button.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    button.MouseButton1Click:Connect(function()
        self.Window:Minimize()
    end)
end

return FluentHelper
