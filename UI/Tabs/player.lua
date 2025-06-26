local playerTab = {}
playerTab.__index = playerTab

function playerTab:load(FluentUI)
    local self = setmetatable({}, playerTab)
    self.FluentUI = FluentUI
    self.Fluent = FluentUI.Fluent
    self.Tab = FluentUI.Tabs.player
    self.options = {}


    self:createMovement()
    self:createKeybinds()
    return self
end

function playerTab:createMovement()
    local playerTab = self.Tab
    local movementSection = playerTab:AddSection("Movement")
    self.options.walkSpeedSlider = movementSection:AddSlider("WalkSpeedSlider", {
        Title = "WalkSpeed",
        Description = "Adjust player walk speed",
        Default = shared.main.WalkSpeed,
        Min = 16,
        Max = 70,
        Rounding = 0,
        Callback = function(Value)
            shared.main.WalkSpeed = Value
        end
    })

    self.options.jumpPowerSlider = movementSection:AddSlider("jumpPowerSlider", {
        Title = "JumpPower",
        Description = "Adjust player jump power",
        Default = shared.main.JumpPower,
        Min = 50,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            shared.main.JumpPower = Value
        end
    })
end

function playerTab:createKeybinds()
    local playerTab = self.Tab
    local keybindsSection = playerTab:AddSection("Key bind")
    keybindsSection:AddKeybind("BackToHiveBind", {
        Title = "Back To Hive",
        Mode = "Toggle",
        Default = "B",
        Callback = function()
            self:handleBackToHive()
        end
    })
    
    keybindsSection:AddKeybind("ToggleBotBind", {
        Title = "Toggle Bot",
        Mode = "Toggle",
        Default = "Q",
        Callback = function()
            self:handleToggleBot()
        end
    })
end

function playerTab:handleBackToHive()
    if shared.Bot then
        local pos = shared.Helpers.Hive:getHivePosition()
        
        if shared.Bot and shared.Bot.isRunning then 
            shared.Bot:stop()
            self.FluentUI.main.options.autoFarmToggle:SetValue(false)
            self.Fluent:Notify({
                Title = "Bot", 
                Content = "Bot stopped", 
                Duration = 3
            })
        end
        print("tween back to hive")
        shared.Helpers.Player:tweenTo(pos, 1)
    end
end

function playerTab:handleToggleBot()
    if not shared.Bot then return end
    
    if shared.Bot.isRunning then
        self.FluentUI.main.options.autoFarmToggle:SetValue(false)
    else
        self.FluentUI.main.options.autoFarmToggle:SetValue(true)
    end
end
return playerTab