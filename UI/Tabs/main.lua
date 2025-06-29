local HttpService = game:GetService("HttpService")
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
    self.options.priorityTokens = farmSettinSection:AddDropdown("priorityTokens", {
        Title = "Priority Tokens",
        Values = shared.Data.TokenData:getRareToken(true),
        Multi = true,
        Default = {},
        Callback = function(tokensName)
            local tokens = {}
            for tokenName, state in pairs(tokensName) do
                table.insert(tokens, tokenName)
            end
            shared.main.farm.priorityTokens = tokens
        end

    })
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
    self.autoFarmSprout = farmSettinSection:AddToggle("autoFarmSprout", {
        Title = "Farm Sprout",
        Default = false,
        Callback = function(val)
            shared.main.auto.autoFarmSprout = val
        end
    })

    local playerHelper = shared.Helpers.Player
    local equipedMask = playerHelper:getEquippedMask()
    local maskIndex =  playerHelper:getMaskIndex(equipedMask)
    local farmSettinSection = self.Tab:AddSection("Convert Setting")
    self.autoHoneyMask = farmSettinSection:AddToggle("autoHoneyMask", {
        Title = "Auto Honey Mask",
        Description = "Automatically equip Honey Mask when converting",
        Default = shared.main.auto.autoHoneyMask,
        Callback = function(val)
            shared.main.auto.autoHoneyMask = val
        end
    })
    self.defaultMask = farmSettinSection:AddDropdown("defaultMask", {
        Title = "Default mask",
        Values = playerHelper:getPlayerMasks(),
        Multi = false,
        Default = maskIndex,
        Callback = function(mask)
            shared.main.Equip.defaultMask = mask
            playerHelper:equipMask(mask)
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