local HttpService = game:GetService("HttpService")
local WP = game:GetService("Workspace")
local MonstersFolder = WP:FindFirstChild("Monsters")
local MonsterSpawnersFolder = WP:FindFirstChild("MonsterSpawners")
local spawnerKey = {
    ["MushroomBush"]      = { field = "Mushroom Field",     name = "Ladybug",      avoidDistance = 30 },
    ["Ladybug Bush"]      = { field = "Clover Field",       name = "Ladybug",      avoidDistance = 30 },
    ["Ladybug Bush 2"]    = { field = "Strawberry Field",   name = "Ladybug",      avoidDistance = 30 },
    ["Ladybug Bush 3"]    = { field = "Strawberry Field",   name = "Ladybug",      avoidDistance = 30 },

    ["PineappleBeetle"]   = { field = "Pineapple Patch",    name = "Rhino Beetle", avoidDistance = 30 },
    ["PineappleMantis1"]  = { field = "Pineapple Patch",    name = "Mantis",       avoidDistance = 30 },

    ["ForestMantis1"]     = { field = "Pine Tree Forest",   name = "Mantis",       avoidDistance = 30 },
    ["ForestMantis2"]     = { field = "Pine Tree Forest",   name = "Mantis",       avoidDistance = 30 },

    ["Rhino Bush"]        = { field = "Clover Field",       name = "Rhino Beetle", avoidDistance = 30 },
    ["Rhino Cave 1"]      = { field = "Blue Flower Field",  name = "Rhino Beetle", avoidDistance = 30 },
    ["Rhino Cave 2"]      = { field = "Bamboo Field",       name = "Rhino Beetle", avoidDistance = 30 },
    ["Rhino Cave 3"]      = { field = "Bamboo Field",       name = "Rhino Beetle", avoidDistance = 30 },

    ["Spider Cave"]       = { field = "Spider Field",       name = "Spider",       avoidDistance = 30 },

    ["RoseBush"]          = { field = "Rose Field",         name = "Scorpion",     avoidDistance = 30 },
    ["RoseBush2"]         = { field = "Rose Field",         name = "Scorpion",     avoidDistance = 30 },

    ["WerewolfCave"]      = { field = "Cactus Field",       name = "Werewolf",     avoidDistance = 30 },

    ["StumpSnail"]        = { field = "Stump Field",        name = "Stump Snail",  avoidDistance = 30 },
    ["CoconutCrab"]       = { field = "Coconut Field",      name = "Coconut Crab", avoidDistance = 30 },
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
    local success, result = pcall(function()
        local player = game.Players.LocalPlayer
        if not player then return 0 end
        
        local char = player.Character
        if not char then return 0 end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        
        if not root or not humanoid or humanoid.Health <= 0 then 
            return 0 
        end
        
        local count = 0
        
        if not self.Monsters then return 0 end
        
        for _, monster in ipairs(self.Monsters) do
            if monster and monster.Parent then
                local mRoot = monster.PrimaryPart
                if mRoot and mRoot.Parent then
                    local home = monster:FindFirstChild("Home")
                    if home and home.Value then
                        local monsterData = spawnerKey and spawnerKey[home.Value.Name]
                        if monsterData and monsterData.avoidDistance then
                            local distance = (Vector3.new(mRoot.Position.X, 0, mRoot.Position.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
                            if distance <= monsterData.avoidDistance then
                                count += 1
                            end
                        end
                    end
                end
            end
        end
        
        return count
    end)
    
    if success then
        return result
    else
        warn("Error in getCloseMonsterCount: " .. tostring(result))
        return 0
    end
end


function MonsterHelper:getClosestMonster()
    local player = game.Players.LocalPlayer
    if not player then return nil end

    local char = player.Character
    if not char then return nil end

    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")

    if not root or not humanoid or humanoid.Health <= 0 then 
        return nil 
    end

    local closestMonster = nil
    local closestDistance = math.huge

    for _, monster in ipairs(self.Monsters) do
        if monster and monster.Parent then
            local mRoot = monster.PrimaryPart
            if mRoot and mRoot.Parent then
                local distance = (mRoot.Position - root.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestMonster = monster
                end
            end
        end
    end

    return closestMonster
end

return MonsterHelper