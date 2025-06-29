local HttpService = game:GetService("HttpService")
local Rep = game:GetService("ReplicatedStorage")
local combatUI = {}
combatUI.__index = combatUI

function combatUI:load(FluentUI)
    local self = setmetatable({}, combatUI)
    self.Fluent = FluentUI.Fluent
    self.Tab = FluentUI.Tabs.combat

    self.autoHuntMonster = self.Tab:AddToggle("autoHuntMonster", {
        Title = "Auto Hunt Monsters",
        Description = "⚔️ Automatically hunts spawned monsters on the map.",
        Default = false,
        Callback = function(val)
            shared.main.auto.autoHunt = val
        end
    })
    local monsterToHuntSection = self.Tab:AddSection("Monsters to hunt")
    self.monsterToHunt = monsterToHuntSection:AddDropdown("monsterToHunt", {
        Title = "Select Monsters",
        Description = "📋 Choose which monsters to hunt automatically.",
        Values = { "Ladybug", "Rhino Beetle", "Spider", "Mantis", "Werewolf", "Scorpion"},
        Multi = true,
        Default = {},
        Callback = function(monsters)
            shared.main.Monster.enabledMonsters = monsters
        end
    })

    self:createStatus(self.Tab)
end
function combatUI:createStatus(section)
    local monsterStatusSection = section:AddSection("Monsters Status")

    local monsterStatusList = {
        {name = "Ladybug"},
        {name = "Rhino Beetle"},
        {name = "Spider"},
        {name = "Werewolf"},
        {name = "Mantis"},
        {name = "Scorpion"},
    }


    local contentLines = {}
    for _, monster in ipairs(monsterStatusList) do
        table.insert(contentLines, "🔴 | " .. monster.name)
    end

    self.monsterStatusInfo = monsterStatusSection:AddParagraph({
        Title = "Monster Status",
        Content = table.concat(contentLines, "\n")
    })

end

return combatUI