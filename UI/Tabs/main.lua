local Rep = game:GetService("ReplicatedStorage")
local mainTab = {}
mainTab.__index = mainTab

function mainTab:load(FluentUI)
    local self = setmetatable({}, mainTab)
    self.Fluent = FluentUI.Fluent
    self.Tab = FluentUI.Tabs.main
    self.options = {}

    self.options.FieldDropdown = self.Tab:AddDropdown("FieldDropdown", {
        Title = "🌾 Select Field",
        Values = shared.Helpers.Field:getAllFieldDisplayNames(),
        Multi = false,
        Default = 1,
        Callback = function(field)
            shared.Helpers.Field:SetCurrentField(field)
        end

    })
    
    local mainSection = self.Tab:AddSection("Farm section")
    self.options.autoFarmToggle = mainSection:AddToggle("autoFarmToggle", {
        Title = "Auto Farm",
        Default = false,
        Callback = function(val)
            task.spawn(function()
                if shared.Bot then
                    if val then 
                        shared.Bot:start() 
                    else 
                        shared.Bot:stop() 
                    end
                end
            end)
        end
    })
    self.options.autoDig = mainSection:AddToggle("autoDig", {
        Title = "Auto Dig",
        Default = false,
        Callback = function(value)
            shared.main.auto.autoDig = value
            if value then
                self:startAutoDigLoop()
            end
        end
    })
    self.options.autoSprinkler = mainSection:AddToggle("autoSprinkler", {
        Title = "Auto Sprinkler",
        Default = false,
        Callback = function(value)
            shared.main.auto.autoSprinkler = value
        end
    })

    local farmSettinSection = self.Tab:AddSection("Farm Setting")
    self.options.ignoreHoneyToken = farmSettinSection:AddToggle("ignoreHoneyToken", {
        Title = "Ignore Honey Tokens",
        Default = shared.main.farm.ignoreHoneyToken,
        Callback = function(value)
            shared.main.farm.ignoreHoneyToken = value
        end
    })

    self.options.farmBubble = farmSettinSection:AddToggle("farmBubble", {
        Title = "Farm Bubble",
        Default = false,
        Callback = function(value)
            shared.main.farm.farmBubble = value
        end
    })
    return self
end
function mainTab:startAutoDigLoop()
    task.spawn(function()
        while shared.main.auto.autoDig do
            if not shared.Helpers.Player:isCapacityFull() then
                local Event = Rep.Events.ToolCollect
                Event:FireServer()
            end
            task.wait(0.4)
        end
    end)
end
return mainTab