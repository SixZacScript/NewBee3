local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Rep = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlanters = require(Rep.LocalPlanters)


local PlayerHelper = {}
PlayerHelper.__index = PlayerHelper

-- Constructor
function PlayerHelper.new()
    local self = setmetatable({}, PlayerHelper)
    self.localPlayer = Players.LocalPlayer
    self.localPlayer.CameraMaxZoomDistance = 300
    
    -- Wait for CoreStats once and cache references
    self.CoreStats = self.localPlayer:WaitForChild("CoreStats")
    self.pollenStat = self.CoreStats:WaitForChild("Pollen")
    self.honeyStat = self.CoreStats:WaitForChild("Honey")
    self.capacityStat = self.CoreStats:WaitForChild("Capacity")
    self.gameGUi = self:getScreenGui()
    
    -- Initialize stats
    self.Pollen = self.pollenStat.Value
    self.Honey = self.honeyStat.Value
    self.Capacity = self.capacityStat.Value
    self:getPlayerStats()
    -- Initialize character references
    self:updateCharacterReferences(self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait())
    
    self:setupConnections()
    self:setupPlanterListener()
    return self
end

function PlayerHelper:updateCharacterReferences(character)
    self.character = character
    if character then
        self.humanoid = character:WaitForChild("Humanoid")
        self.rootPart = character:WaitForChild("HumanoidRootPart")
        
        local defaultProps = PhysicalProperties.new(2, 1, 0.8, 0.1, 0.2)
        self.rootPart.CustomPhysicalProperties = defaultProps
        self.localPlayer.CameraMaxZoomDistance = 300
    else
        self.humanoid = nil
        self.rootPart = nil
    end
end

function PlayerHelper:setupConnections()
    -- Character management
    self.characterConnection = self.localPlayer.CharacterAdded:Connect(function(character)
        self:updateCharacterReferences(character)
        
        -- Connect to new humanoid's Died event
        if self.humanoidConnection then
            self.humanoidConnection:Disconnect()
        end
        
        self.humanoidConnection = self.humanoid.Died:Connect(function()
            self:updateCharacterReferences(nil)
        end)
    end)
    
    -- Connect to initial humanoid if it exists
    if self.humanoid then
        self.humanoidConnection = self.humanoid.Died:Connect(function()
            self:onPlayerDied()
            self:updateCharacterReferences(nil)
        end)

        if self._enforceStatsConnection then
            self._enforceStatsConnection:Disconnect()
        end

        self._enforceStatsConnection = RunService.Heartbeat:Connect(function()
            if self.humanoid then
                local humanoid = self.humanoid
                local JumpPower = shared.main.JumpPower or humanoid.JumpPower or 50
                local WalkSpeed = shared.main.WalkSpeed or humanoid.WalkSpeed or 16
                if humanoid.JumpPower ~= JumpPower then
                    humanoid.JumpPower = JumpPower
                end
                if humanoid.WalkSpeed ~= WalkSpeed then
                    humanoid.WalkSpeed = WalkSpeed
                end
            end
        end)

    end
    
    -- Stat connections using cached references
    self.pollenConnection = self.pollenStat.Changed:Connect(function(val)
        self.Pollen = val
    end)
    
    self.capacityConnection = self.capacityStat.Changed:Connect(function(val)
        self.Capacity = val
    end)
    
    -- Optional: Connect to honey changes if needed
    self.honeyConnection = self.honeyStat.Changed:Connect(function(val)
        self.Honey = val
    end)
end

function PlayerHelper:setupPlanterListener()
    task.spawn(function()
        while true do
            local active = self:getActivePlanter()
            local Slots = shared.main.Planter.Slots or {}

            if shared.FluentUI and shared.FluentUI.planter then  
                for i = 1, 3 do
                    local slotConfig = Slots[i]
                    local slot = shared.FluentUI.planter.options["activePlanterSlot" .. i]

                    if slot then
                        if slot.PlanterType == "None" then continue end
                        local found = false

                        for _, planter in ipairs(active) do
                            local growthPercent = math.floor(planter.GrowthPercent * 1000) * 0.1

                            if slotConfig.PlanterType == planter.Type then
                                found = true
                                local statusText = string.format(
                                    "%s | Growth: %.1f%%",
                                    planter.Type,
                                    growthPercent
                                )

                                if planter.canHarvest then
                                    statusText = "✅ Ready | " .. statusText
                                else
                                    statusText = "❌ Not ready | " .. statusText
                                end
                                slot:SetDesc(statusText)
                            end
                        end

                        if not found then
                            slot:SetDesc("No planter is currently placed.")
                        end
                    end
                end
            end

            task.wait(1)
        end
    end)
end

function PlayerHelper:isCapacityFull()
    return self.Pollen >= self.Capacity
end


function PlayerHelper:isValid()
    return self.localPlayer and self.character and self.humanoid and 
           self.rootPart and self.humanoid.Health > 0
end


function PlayerHelper:stopMoving()
    self.blockedParts = self.blockedParts and self.blockedParts or {}
    if not self:isValid() then return end

    if self.tweenMonitorConnection then
        self.tweenMonitorConnection:Disconnect()
        self.tweenMonitorConnection = nil
    end

    if #self.blockedParts > 0 then
        for _, part in ipairs(self.blockedParts) do
            if part and part:IsDescendantOf(workspace) then
                part.CanCollide = true
            end
        end
        self.blockedParts = {}
    end

    self.humanoid:Move(Vector3.zero)
    self.humanoid:MoveTo(self.rootPart.Position)
    self:setCharacterAnchored(false)
    self:disableWalking(false)
end
function PlayerHelper:setCharacterAnchored(state)
    if not self:isValid() then return end
    self.rootPart.Anchored = state
end


function PlayerHelper:tweenTo(targetPosition, duration, callback)
    if not self:isValid() then return false end

    self:setCharacterAnchored(true)

    if self.activeTween then
        self.activeTween:Cancel()
        self.activeTween = nil
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {self.character}
    rayParams.IgnoreWater = true

    self.blockedParts = {}
    local direction = targetPosition - self.rootPart.Position
    local rayResult = workspace:Raycast(self.rootPart.Position, direction, rayParams)

    if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
        rayResult.Instance.CanCollide = false
        table.insert(self.blockedParts, rayResult.Instance)
    end

    -- Create Tween
    local tween = TweenService:Create(self.rootPart, TweenInfo.new(
        duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut
    ), {CFrame = CFrame.new(targetPosition)})

    self.activeTween = tween
    local completed = false

    local function restoreBlockedParts()
        for _, part in ipairs(self.blockedParts) do
            if part and part:IsDescendantOf(workspace) then
                part.CanCollide = true
            end
        end
        self.blockedParts = {}
    end

    local function cleanup()
        if self.tweenMonitorConnection then
            self.tweenMonitorConnection:Disconnect()
            self.tweenMonitorConnection = nil
        end
    end

    self.tweenMonitorConnection = RunService.Heartbeat:Connect(function()
        if completed then return end
        if not self:isValid() then
            completed = true
            tween:Cancel()
            self:setCharacterAnchored(false)
            cleanup()
            restoreBlockedParts()
        end
    end)

    tween.Completed:Connect(function()
        if completed then return end
        completed = true
        self:setCharacterAnchored(false)
        cleanup()
        restoreBlockedParts()
        self.activeTween = nil
        if callback then callback() end
    end)

    tween:Play()
    return true
end

function PlayerHelper:isPlayerInField(field)
    if not field or not field:IsA("BasePart") or not self.rootPart then
        return false
    end

    local fieldCenter = Vector3.new(field.Position.X, 0, field.Position.Z)
    local playerPos = Vector3.new(self.rootPart.Position.X, 0, self.rootPart.Position.Z)

    local halfSizeX = field.Size.X / 2 + 5 
    local halfSizeZ = field.Size.Z / 2 + 5

    local dx = math.abs(playerPos.X - fieldCenter.X)
    local dz = math.abs(playerPos.Z - fieldCenter.Z)

    return dx <= halfSizeX and dz <= halfSizeZ
end

function PlayerHelper:getPlayerStats()
    local success, plrStats = pcall(function()
        local RetrievePlayerStats = Rep.Events.RetrievePlayerStats
        return RetrievePlayerStats:InvokeServer()
    end)
    if not success then
        warn("Failed to retrieve player stats:", plrStats)
        return {}
    end
    self.plrStats = plrStats
    self.Honeycomb = plrStats.Honeycomb
    self.Accessories = plrStats.Accessories or {}
    self.EquippedSprinkler = plrStats.EquippedSprinkler


    writefile("playerStats.json", HttpService:JSONEncode(plrStats))
    return self.plrStats
end

function PlayerHelper:getInventoryItem(itemName)
    local cleanName = string.lower(string.gsub(itemName, "%s+", ""))
    local playerData = self.plrStats
    if not playerData then 
        warn("Player data not found.")
        return 0 
    end
    local inventory = playerData.Eggs
    if not inventory then
        warn("inventory not found")
        return 0
    end

    -- Normalize inventory keys
    local normalizedInventory = {}
    for key, value in pairs(inventory) do
        local cleanKey = string.lower(string.gsub(key, "%s+", ""))
        normalizedInventory[cleanKey] = value
    end

    local item = normalizedInventory[cleanName] or 0
    if item then
        return item
    end
    
    warn("item not found")
    return 0
end


function PlayerHelper:equipMask(mask)
    mask = mask or (shared.main and shared.main.Equip and shared.main.Equip.defaultMask)

    if not mask then return false end

    if table.find(self.plrStats.Accessories, mask) then
        local Event = game:GetService("ReplicatedStorage").Events.ItemPackageEvent
        Event:InvokeServer("Equip", {Category = "Accessory", Type = mask})
    end
    return true
end


function PlayerHelper:disableWalking(disable)
    local humanoid = self.humanoid
    if humanoid then
        humanoid.WalkSpeed = disable and 0 or shared.main.WalkSpeed
        humanoid.JumpPower = disable and 0 or shared.main.JumpPower
    end

    if self.localPlayer == game.Players.LocalPlayer then
        local ContextActionService = game:GetService("ContextActionService")
        if disable then
            ContextActionService:BindAction("DisableMovement", function()
                return Enum.ContextActionResult.Sink
            end, false, unpack(Enum.PlayerActions:GetEnumItems()))
        else
            ContextActionService:UnbindAction("DisableMovement")
        end
    end
end

function PlayerHelper:getCanHarvestPlanter()
    local allPlanters = self:getActivePlanter()

    for _, planter in ipairs(allPlanters) do
        if planter.canHarvest then return planter end
    end

    return nil
end

function PlayerHelper:getActivePlanter()
    local myPlanters = debug.getupvalue(LocalPlanters.LoadPlanter, 4)
    local Planters = {}
    local slotConfig = shared.main.Planter.Slots

    for _, planter in ipairs(myPlanters) do
        if planter.Owner.Name ~= self.localPlayer.Name then continue end
        local percent100 = planter.GrowthPercent * 100
        table.insert(Planters, {
            Type = planter.Type,
            Position = planter.Pos,
            ActorID = planter.ActorID,
            GrowthPercent = planter.GrowthPercent,
            percent100 = percent100,
            canHarvest = false,
        })
       
    end

    -- ตรวจสอบว่าควร harvest ไหม
    for _, slot in ipairs(slotConfig) do
        if slot.PlanterType == "None" then continue end
        for _, planter in ipairs(Planters) do
            if slot.PlanterType == planter.Type then
                if planter.percent100 >= slot.HarvestAt then
                    planter.canHarvest = true
                end
                planter.Field = slot.Field
                slot.Placed = true
                break
            else
                slot.Placed = false
            end
        end
    end

    shared.main.Planter.Actives = Planters
    return Planters
end

function PlayerHelper:getPlanterToPlace()
    local activePlanters = self:getActivePlanter()
    local slots = shared.main.Planter.Slots

    for _, slot in ipairs(slots) do
        if slot.PlanterType == "None" then continue end
        local planterFullname = self:getPlanterFullName(slot.PlanterType)
        local planterAmount = self:getInventoryItem(planterFullname)

        if planterAmount == 0 then
            continue
        end

        local found = false
        for _, planter in ipairs(activePlanters) do
            if planter.Type == slot.PlanterType then
                found = true
                break
            end
        end

        if not found then
            return slot
        end
    end

    return nil
end

function PlayerHelper:getPlanterFullName(shortName)
    local fullNameMap = {
        ['Paper']        = "Paper Planter",
        ['Ticket']       = "Ticket Planter",
        ['Sticker']      = "Sticker Planter",
        ['Festive']      = "Festive Planter",
        ['Plastic']      = "Plastic Planter",
        ['Candy']        = "Candy Planter",
        ["Red Clay"] = "Red Clay Planter",
        ["Blue Clay"]= "Blue Clay Planter",
        ['Tacky']        = "Tacky Planter",
        ['Pesticide']    = "Pesticide Planter",
        ["Heat-Treated"] = "Heat‑Treated Planter",
        ['Hydroponic']   = "Hydroponic Planter",
        ['Petal']        = "Petal Planter",
        ["Planter Of Plenty"] = "Planter Of Plenty"
    }

    return fullNameMap[shortName] or (shortName .. " Planter")
end
function PlayerHelper:getScreenGui()
    local ScreenGui = nil
    local plyerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui", true)
    for index, gui in plyerGui:GetChildren() do
        if gui and gui:FindFirstChild("ActivateButton") then
            ScreenGui = gui
        end
    end
    if ScreenGui then
        local ShopGui = ScreenGui.Shop
        local Scroller = ShopGui.Scroller
        local BuyButton: TextButton = Scroller.BuyButton
        BuyButton.MouseButton1Click:Connect(function()
            self:getPlayerStats()
            local paperAmount = self:getInventoryItem('PaperPlanter')
            print("player cratf/buy something", paperAmount)
        end)
        return ScreenGui
    end

    return nil
end

function PlayerHelper:click(pos)
    if typeof(pos) ~= "UDim2" then
        warn("Expected UDim2 for position")
        return
    end

    local screenSize = workspace.CurrentCamera.ViewportSize
    local x = pos.X.Scale * screenSize.X + pos.X.Offset
    local y = pos.Y.Scale * screenSize.Y + pos.Y.Offset

    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)

end

function PlayerHelper:onPlayerDied()
    local Bot = shared.Bot

    if Bot and Bot.isRunning then
        Bot:stop()
    end

    print("Player has died. Waiting for respawn...")

    -- Wait for new character
    self.localPlayer.CharacterAdded:Wait()
    shared.FluentUI.Fluent:Notify({
        Title = "Bot", 
        Content = "Player respawned. Bot will start in 3 seconds...", 
        Duration = 3
    })

    task.wait(3)
    if Bot and not Bot.isRunning then
        Bot:start()
    end
end



function PlayerHelper:destroy()
    if self.characterConnection then self.characterConnection:Disconnect() end
    if self.humanoidConnection then self.humanoidConnection:Disconnect() end
    if self.pollenConnection then self.pollenConnection:Disconnect() end
    if self.capacityConnection then self.capacityConnection:Disconnect() end
    if self.honeyConnection then self.honeyConnection:Disconnect() end
    if self._enforceStatsConnection then self._enforceStatsConnection:Disconnect() end
    
    self.localPlayer = nil
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil
end

return PlayerHelper