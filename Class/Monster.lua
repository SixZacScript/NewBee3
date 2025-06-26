local HttpService = game:GetService("HttpService")
local WP = game:GetService("Workspace")
local MonstersFolder = WP:FindFirstChild("Monsters")
local MonsterSpawnersFolder = WP:FindFirstChild("MonsterSpawners")
local spawnerKey = {
    ["MushroomBush"]      = { field = "Mushroom Field",     name = "Ladybug",      avoidDistance = 40 },
    ["Ladybug Bush"]      = { field = "Clover Field",       name = "Ladybug",      avoidDistance = 40 },
    ["Ladybug Bush 2"]    = { field = "Strawberry Field",   name = "Ladybug",      avoidDistance = 40 },
    ["Ladybug Bush 3"]    = { field = "Strawberry Field",   name = "Ladybug",      avoidDistance = 40 },

    ["PineappleBeetle"]   = { field = "Pineapple Patch",    name = "Rhino Beetle", avoidDistance = 40 },
    ["PineappleMantis1"]  = { field = "Pineapple Patch",    name = "Mantis",       avoidDistance = 25 },

    ["ForestMantis1"]     = { field = "Pine Tree Forest",   name = "Mantis",       avoidDistance = 25 },
    ["ForestMantis2"]     = { field = "Pine Tree Forest",   name = "Mantis",       avoidDistance = 25 },

    ["Rhino Bush"]        = { field = "Clover Field",       name = "Rhino Beetle", avoidDistance = 40 },
    ["Rhino Cave 1"]      = { field = "Blue Flower Field",  name = "Rhino Beetle", avoidDistance = 40 },
    ["Rhino Cave 2"]      = { field = "Bamboo Field",       name = "Rhino Beetle", avoidDistance = 40 },
    ["Rhino Cave 3"]      = { field = "Bamboo Field",       name = "Rhino Beetle", avoidDistance = 40 },

    ["Spider Cave"]       = { field = "Spider Field",       name = "Spider",       avoidDistance = 40 },

    ["RoseBush"]          = { field = "Rose Field",         name = "Scorpion",     avoidDistance = 40 },
    ["RoseBush2"]         = { field = "Rose Field",         name = "Scorpion",     avoidDistance = 40 },

    ["WerewolfCave"]      = { field = "Cactus Field",       name = "Werewolf",     avoidDistance = 40 },

    ["StumpSnail"]        = { field = "Stump Field",        name = "Stump Snail",  avoidDistance = 40 },
    ["CoconutCrab"]       = { field = "Coconut Field",      name = "Coconut Crab", avoidDistance = 40 },
}



local MonsterHelper = {}
MonsterHelper.__index = MonsterHelper

function MonsterHelper.new()
    local self = setmetatable({}, MonsterHelper)
    self.Monsters = {}
    self.connections = {} 

    self:setupListener()
    return self
end


function MonsterHelper:checkMonsterForTarget(monster)
    local player = game.Players.LocalPlayer
    for _, descendant in ipairs(monster:GetDescendants()) do
        if descendant.Name == "Target" and descendant:IsA("ObjectValue") then
            if descendant.Value == player.Character then
                if not table.find(self.Monsters, monster) then
                    table.insert(self.Monsters, monster)
                end
            end
            break 
        end
    end
end
function MonsterHelper:setupListener()
    self.connections.folderChildAdded = MonstersFolder.ChildAdded:Connect(function(monster)
        task.spawn(function()
            task.wait(0.25) -- delay for child added
            self:checkMonsterForTarget(monster)
        end)
    end)

    self.connections.folderChildRemoved = MonstersFolder.ChildRemoved:Connect(function(monster)
        local index = table.find(self.Monsters, monster)
        if index then 
            table.remove(self.Monsters, index) 
        end
    end)
end

function MonsterHelper:getCloseMonsterCount()
    local player = game.Players.LocalPlayer
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local count = 0

    if not root or (char and char.Humanoid.Health) <= 0 then return 0 end
    for _, monster in ipairs(self.Monsters) do
        local mRoot = monster.PrimaryPart
        if mRoot then
            local monsterData = spawnerKey[monster.Home.Value.Name]
            local distance = (mRoot.Position - root.Position).Magnitude
            if monsterData and distance <= monsterData.avoidDistance then
                count += 1
            end
        end

    end
    return count
end

return MonsterHelper