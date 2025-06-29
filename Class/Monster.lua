local HttpService = game:GetService("HttpService")
local WP = game:GetService("Workspace")
local MonstersFolder = WP:FindFirstChild("Monsters")
local MonsterSpawnersFolder = WP:FindFirstChild("MonsterSpawners")
local spawnerKey = {
    ["MushroomBush"]      = { field = "Mushroom Field",     name = "Ladybug",      avoidDistance = 16 },
    ["Ladybug Bush"]      = { field = "Clover Field",       name = "Ladybug",      avoidDistance = 16 },
    ["Ladybug Bush 2"]    = { field = "Strawberry Field",   name = "Ladybug",      avoidDistance = 16 },
    ["Ladybug Bush 3"]    = { field = "Strawberry Field",   name = "Ladybug",      avoidDistance = 16 },

    ["PineappleBeetle"]   = { field = "Pineapple Patch",    name = "Rhino Beetle", avoidDistance = 16 },
    ["PineappleMantis1"]  = { field = "Pineapple Patch",    name = "Mantis",       avoidDistance = 45 },

    ["ForestMantis1"]     = { field = "Pine Tree Forest",   name = "Mantis",       avoidDistance = 45 },
    ["ForestMantis2"]     = { field = "Pine Tree Forest",   name = "Mantis",       avoidDistance = 45 },

    ["Rhino Bush"]        = { field = "Clover Field",       name = "Rhino Beetle", avoidDistance = 16 },
    ["Rhino Cave 1"]      = { field = "Blue Flower Field",  name = "Rhino Beetle", avoidDistance = 16 },
    ["Rhino Cave 2"]      = { field = "Bamboo Field",       name = "Rhino Beetle", avoidDistance = 16 },
    ["Rhino Cave 3"]      = { field = "Bamboo Field",       name = "Rhino Beetle", avoidDistance = 16 },

    ["Spider Cave"]       = { field = "Spider Field",       name = "Spider",       avoidDistance = 25 },

    ["RoseBush"]          = { field = "Rose Field",         name = "Scorpion",     avoidDistance = 24 },
    ["RoseBush2"]         = { field = "Rose Field",         name = "Scorpion",     avoidDistance = 24 },

    ["WerewolfCave"]      = { field = "Cactus Field",       name = "Werewolf",     avoidDistance = 30 },

    ["StumpSnail"]        = { field = "Stump Field",        name = "Stump Snail",  avoidDistance = 16 },
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
   

    task.spawn(function()
        while true do
            local monsterData = MonsterHelper:getMonsterStatus()
            local contentLines = {}
            for _, monster in ipairs(monsterData) do
                local statusIcon = monster.isSpawned and "🟢" or "🔴"
                local line = statusIcon .. " | " .. (monster.isSpawned and monster.name or (monster.name .." | ".. monster.timer))
                table.insert(contentLines, line)
            end

            if shared.FluentUI and shared.FluentUI.combat then  
                shared.FluentUI.combat.monsterStatusInfo:SetDesc(table.concat(contentLines, "\n"))
            end

            task.wait(1)
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


function MonsterHelper:getMonsterStatus()
    local monstersStatus = {} -- key: monsterName, value: isSpawned

    -- Create a set of monster names based on spawnerKey
    local monsterGroups = {}
    for _, v in pairs(spawnerKey) do
        if not monsterGroups[v.name] then
            monsterGroups[v.name] = {
                name = v.name,
                timer = nil,
                shortestTime = math.huge,
                isSpawned = false,
                field =  v.field,
            }
        end
    end

    for _, spawner in ipairs(MonsterSpawnersFolder:GetChildren()) do
        local monsterTypeObj = spawner:FindFirstChild("MonsterType")
        local attachment = spawner:FindFirstChildWhichIsA("Attachment")

        local monsterObject = spawnerKey[spawner.Name]
        if not monsterObject then continue end

        local monsterName = monsterObject.name

        if monsterTypeObj and attachment then
            local timerLabel = attachment:FindFirstChild("TimerGui") and attachment.TimerGui:FindFirstChild("TimerLabel")
            if timerLabel then
                local isSpawned = not timerLabel.Visible

                if isSpawned then
                    monsterGroups[monsterName].isSpawned = true
                    monsterGroups[monsterName].field = monsterObject.field
                elseif not monsterGroups[monsterName].isSpawned then
                    local text = timerLabel.Text
                    local minutes, seconds = string.match(text, ":(%d+):(%d+)")
                    if not minutes or not seconds then
                        minutes, seconds = string.match(text, "(%d+):(%d+)")
                    end
                    if minutes and seconds then
                        local totalSeconds = tonumber(minutes) * 60 + tonumber(seconds)
                        if totalSeconds < monsterGroups[monsterName].shortestTime then
                            monsterGroups[monsterName].shortestTime = totalSeconds
                            monsterGroups[monsterName].timer = minutes .. ":" .. seconds
                        end
                    end
                end
            end
        end
    end

    for _, data in pairs(monsterGroups) do
        table.insert(monstersStatus, {
            name = data.name,
            timer = data.timer or "--:--",
            isSpawned = data.isSpawned,
            field = data.field,
        })
    end

    return monstersStatus
end

return MonsterHelper