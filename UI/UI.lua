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
    local viewportSize = workspace.CurrentCamera.ViewportSize

    local width = math.clamp(viewportSize.X * 0.6, 300, 600)
    local height = math.clamp(viewportSize.Y * 0.6, 300, 500)

    self.Window = self.Fluent:CreateWindow({
        Title = "Fluent",
        SubTitle = "by dawid",
        TabWidth = 160,
        Size = UDim2.fromOffset(width, height),
        Acrylic = true,
        Theme = "Darker",
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


    self.SaveManager:SetLibrary(self.Fluent)
    self.InterfaceManager:SetLibrary(self.Fluent)
    self.InterfaceManager:SetFolder("FluentScriptHub")
    self.SaveManager:SetFolder("FluentScriptHub/specific-game")

    self.InterfaceManager:BuildInterfaceSection(self.Tabs.Settings)
    self.SaveManager:BuildConfigSection(self.Tabs.Settings)

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
return FluentHelper
