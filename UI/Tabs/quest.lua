local HttpService = game:GetService("HttpService")
local Rep = game:GetService("ReplicatedStorage")
local questTab = {}
questTab.__index = questTab

function questTab:load(FluentUI)
    local self = setmetatable({}, questTab)
    self.Fluent = FluentUI.Fluent
    self.Tab = FluentUI.Tabs.quest

    
    self.autoQuestToggle = self.Tab:AddToggle("autoQuestToggle", {
        Title = "Auto Quest",
        Default = false
    })
    self.doNPCquest = self.Tab:AddDropdown("doNPCquest", {
        Title = "Do NPC Quests",
        Description = "Select NPCs to do quests.",
        Values = shared.Helpers.Npc:getNpcNames(),
        Multi = true,
        Default = {},
        Callback = function(vals)
            shared.main.Quest.enabledNPCs = vals
        end
    })

    local questSettingSection = self.Tab:AddSection("Quest Settings")
    self:_createBestFieldDropdowns(questSettingSection)
    

end

function questTab:_createBestFieldDropdowns(section)
    local fieldHelper = shared.Helpers.Field
    local fieldTypes = fieldHelper.FIELD_TYPE

    local fieldConfigs = {
        {name = "bestWhiteField", type = fieldTypes.WHITE, title ="Best white field"},
        {name = "bestBlueField", type = fieldTypes.BLUE, title ="Best blue field"},
        {name = "bestRedField", type = fieldTypes.RED, title ="Best red field"}
    }


    for _, config in pairs(fieldConfigs) do
        local values = fieldHelper:getFieldsByType(config.type) or {}

        self[config.name] = section:AddDropdown(config.name, {
            Title = config.title,
            Values = values,
            Multi = false,
            Default = 1,
        })

        self[config.name]:OnChanged(function(Value)
            shared.main.Quest[config.name] = Value
        end)
    end
end

return questTab