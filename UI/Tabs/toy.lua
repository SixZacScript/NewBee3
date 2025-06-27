local HttpService = game:GetService("HttpService")
local Rep = game:GetService("ReplicatedStorage")
local toyTab = {}
toyTab.__index = toyTab

function toyTab:load(FluentUI)
    local self = setmetatable({}, toyTab)
    self.Fluent = FluentUI.Fluent
    self.Tab = FluentUI.Tabs.toy



    local toySection = self.Tab:AddSection("Toy section")
    self.autoClockToggle = toySection:AddToggle("autoClockToggle", {
        Title = "Auto Wealth Clock",
        Default = false,
        Callback = function(value)
            shared.main.auto.autoClock = value
        end
    })

end

return toyTab