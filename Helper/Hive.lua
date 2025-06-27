local WP = game:GetService("Workspace")
local honeycombsFolder = WP:FindFirstChild("Honeycombs")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HiveHelper = {}
HiveHelper.__index = HiveHelper

function HiveHelper.new()
    local self = setmetatable({}, HiveHelper)
    
    task.spawn(function()
        repeat
            task.wait()
        until shared.Helpers.Player
        self.player = shared.Helpers.Player
        self:initHive()
    end)
    return self
end
function HiveHelper:initHive()
    if not honeycombsFolder then
        warn("Honeycombs folder not found")
        return nil
    end
    local currentHive = self:getMyHive()
    if currentHive then
        return currentHive
    end

    local closestHive, closestDist = self:_findClosestAvailableHive(honeycombsFolder)
    if closestHive then
        self:_claimHive(closestHive)
        return closestHive
    else
        print("No available hives found")
        return nil
    end

end
function HiveHelper:_sendClaimInput()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end
function HiveHelper:_claimHive(hive)
    local base = hive:FindFirstChild("patharrow") and hive.patharrow:FindFirstChild("Base")
    if not base then
        warn("Hive base not found")
        return
    end
    
    local basePos = base.Position + Vector3.new(0, 5, 0)
    self.player:tweenTo(basePos, 1, function()
        task.wait(0.2)
        self:_sendClaimInput()
        
        -- Verify claim after delay
        task.delay(0.5, function()
            if self:_verifyHiveClaim() then
                print("Hive claimed successfully.")
            else
                print("Hive claim failed. Retrying...")
                self:initHive() -- Retry
            end
        end)
    end)
end

function HiveHelper:_verifyHiveClaim()
    for _, hive in ipairs(honeycombsFolder:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and owner.Value == self.player.localPlayer then
            self.hive = hive
            self.hiveCells = hive.Cells
            self.CellsFolder = hive.Cells
            return true
        end
    end
    return false
end

function HiveHelper:getHivePosition()
    local currentHive = self:getMyHive()
    if currentHive then
        local base = currentHive:FindFirstChild("patharrow") and currentHive.patharrow:FindFirstChild("Base")
        return base and base.Position + Vector3.new(0, 4, 0)
    end
    return nil
end

function HiveHelper:_findClosestAvailableHive()
    local honeycombs = honeycombsFolder:GetChildren()
    local closestHive, closestDist = nil, math.huge
    local rootPart = self.player.rootPart
    
    local function isHiveAvailable(hive)
        local owner = hive:FindFirstChild("Owner")
        local patharrow = hive:FindFirstChild("patharrow")
        local base = patharrow and patharrow:FindFirstChild("Base")
        
        return base and (not owner or not owner.Value)
    end
        

    if not rootPart then
        warn("Root part not found")
        return nil, math.huge
    end
    
    for _, hive in ipairs(honeycombs) do
        if isHiveAvailable(hive) then
            local base = hive:FindFirstChild("patharrow") and hive.patharrow:FindFirstChild("Base")
            if base then
                local dist = (rootPart.Position - base.Position).Magnitude
                if dist < closestDist then
                    closestHive = hive
                    closestDist = dist
                end
            end
        end
    end
    
    return closestHive, closestDist
end

function HiveHelper:getMyHive()
    for _, hive in ipairs(honeycombsFolder:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and owner.Value == self.player.localPlayer then
            self.hive = hive
            self.CellsFolder = hive.Cells
            return hive
        end
    end
    return nil
end

function HiveHelper:getBalloonData()
    if not self.hive then return 0, 0 end
    if not shared.main.autoConvertBalloon then
        return 0, 0
    end

    local balloonValue, blessingCount = 0, 0
    local nearestDistance = 20
    local hivePosition = self:getHivePosition()

    for _, instance in ipairs(workspace.Balloons.HiveBalloons:GetChildren()) do
        local root = instance:FindFirstChild("BalloonRoot")
        if not (root and root:IsA("BasePart")) then continue end

        local distance = (root.Position - hivePosition).Magnitude
        if distance > nearestDistance then continue end

        nearestDistance = distance

        local gui = instance:FindFirstChild("BalloonBody")
            and instance.BalloonBody:FindFirstChild("GuiAttach")
            and instance.BalloonBody.GuiAttach:FindFirstChild("Gui")

        if gui then
            local barLabel = gui:FindFirstChild("Bar") and gui.Bar:FindFirstChild("TextLabel")
            if barLabel then
                local rawText = barLabel.Text
                local cleanedText = rawText:gsub("[^%d]", "")
                
                if cleanedText ~= "" then
                    balloonValue = tonumber(cleanedText) or 0
                end
            end

            local blessingLabel = gui:FindFirstChild("BlessingBar") and gui.BlessingBar:FindFirstChild("TextLabel")
            if blessingLabel then
                blessingCount = tonumber(blessingLabel.Text:match("x(%d+)")) or 0
            end
        end
    end

    return balloonValue, blessingCount
end
return HiveHelper