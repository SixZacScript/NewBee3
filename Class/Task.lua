local MovementModule = shared.ModuleLoader:load('Class/Movement.lua')
local placeSprinklerEvent = game:GetService("ReplicatedStorage").Events.PlayerActivesCommand
local Services = {
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
}

local TaskManager = {}
TaskManager.__index = TaskManager
function TaskManager.new(bot)
    local self = setmetatable({}, TaskManager)
    self.bot = bot
    self.sprinkler = {
        field = nil,
        placedCount = 0,
    }

    self.connections = {}

    return self
end

function TaskManager:returnToField(position, Callback)
    if not position then return warn('Failed returnToField becuz Position is nil') end

    local player = self.bot.plr
    local fieldPosition = position + Vector3.new(0, 4, 0)
    local thread = coroutine.running()

    local result, msg = player:tweenTo(fieldPosition, 1, function()
        task.wait(.5)
        
        if Callback and typeof(Callback) == "function" then Callback() end
        coroutine.resume(thread, true)
    end)
    if not result then
        warn("Failed to tween: ", msg)
        coroutine.resume(thread, false)
    end
    return coroutine.yield()
end
function TaskManager:harvestPlanter(targetPlanter)
    local playerHelper = self.bot.plr
    local thread = coroutine.running()
    if not targetPlanter then 
        warn("There is no target planter found.")
        return coroutine.resume(thread, false)
    end

    local planterPos = targetPlanter.Position
    local planterFullname = playerHelper:getPlanterFullName(targetPlanter.Type)
    local targetField = shared.Helpers.Field:getFieldByPosition(planterPos)
    local EventCmd = game:GetService("ReplicatedStorage").Events
    local harvestEvt = EventCmd.PlanterModelCollect
    local placeEvt = EventCmd.PlayerActivesCommand
    
    playerHelper:tweenTo(planterPos + Vector3.new(0, 3, 0), 1, function()
        task.wait(1)
        harvestEvt:FireServer(targetPlanter.ActorID)

        task.wait(1)
        placeEvt:FireServer({ Name = planterFullname })
        playerHelper:getPlayerStats()

        self:performCleanupCollection(targetField, {waitTime = 10, ignoreSkill = true})

        return coroutine.resume(thread, true)
    end)

    return coroutine.yield()
end


function TaskManager:placePlanter()
    local thread = coroutine.running()
    local playerHelper = self.bot.plr
    local planterToPlace = playerHelper:getPlanterToPlace() -- is slot
    if not planterToPlace or not planterToPlace.Field then 
        return coroutine.resume(thread, false)
    end

    local targetField = planterToPlace.Field
    local originalFieldName = shared.Helpers.Field:getOriginalFieldName(targetField)


    local fieldPart = shared.Helpers.Field:getField(originalFieldName)
    local EventCmd = game:GetService("ReplicatedStorage").Events
    local placeEvt = EventCmd.PlayerActivesCommand


    local fullName = playerHelper:getPlanterFullName(planterToPlace.PlanterType)
    playerHelper:tweenTo(fieldPart.Position + Vector3.new(0, 3, 0), 1, function()

        task.wait(1)
        placeEvt:FireServer({ Name = fullName })
        playerHelper:getActivePlanter()
        playerHelper:getPlayerStats()

        return coroutine.resume(thread, true)
    end)

    return coroutine.yield()
end

function TaskManager:doSprout(sprout, field)

    local player = self.bot.plr
    if not sprout or not field then
        return warn("sprout or field not found: doSprout")
    end

    -- Early exit if not farming sprouts
    if not self.bot.isRunning or not shared.main.auto.autoFarmSprout then
        return false
    end

    -- Ensure player is in correct field
    if not player:isPlayerInField(field) then
        self:returnToField(field.Position)
    end

    local bot = self.bot
    while bot.isRunning do
        -- Check exit conditions first
        -- if not shared.main.auto.autoFarmSprout or bot:shouldAvoidMonster() then
        if not shared.main.auto.autoFarmSprout then
            return true
        end
        if self:getSproutAmount(sprout) <= 0 then
            break
        end

        self:farming(field)
        if player:isCapacityFull() then return true end

        task.wait()
    end
    
    self:performCleanupCollection(field, {
        waitTime = 20,
        ignoreSkill = true,
    })
    return true
end
function TaskManager:performCleanupCollection(field, options)
    options = options or {}
    local startTime = os.clock()
    local waitTime = options.waitTime or 15
    local playerHelper = shared.Helpers.Player
    local humanoid = playerHelper.humanoid

    while os.clock() - startTime < waitTime and self.bot.isRunning and shared.main.auto.autoFarmSprout and playerHelper:isValid() do
        local token = self.bot.tokenHelper:getBestTokenByField(field, options)

        if token and not token.touched then
            humanoid:MoveTo(token.position)

            local reached = false
            local connection = humanoid.MoveToFinished:Connect(function(reachedFlag)
                reached = reachedFlag
            end)

            repeat
                task.wait()
                if not (self.bot.isRunning and shared.main.auto.autoFarmSprout and playerHelper:isValid()) then
                    break
                end

                local newToken = self.bot.tokenHelper:getBestTokenByField(field, options)
                if (newToken and not newToken.touched and newToken ~= token) or reached then
                    break
                end
            until false

            if connection then connection:Disconnect() end
        end

        task.wait()
    end
end

function TaskManager:farming(currentField, options)
    -- Early exit if bot is not running
    if not self.bot.isRunning then
        return false 
    end
    
    -- Handle monsters before movement
    if self.bot.monsterHelper:getCloseMonsterCount() > 0 then
        self:doJumping()
    end

    local token = self.bot.tokenHelper:getBestTokenByField(currentField, options)
    local targetPos = (token and not token.touched) and token.position or self.bot.Field:getRandomFieldPosition(currentField)
    local playerHelper = shared.Helpers.Player
    local movement = MovementModule.new(playerHelper.humanoid)

    local redirected = false
    movement:SetOnStep(function()
        if not self.bot.isRunning or self.bot.monsterHelper:getCloseMonsterCount() > 0 then
            movement:Stop()
            return false
        end

        if not redirected then
            local newToken = self.bot.tokenHelper:getBestTokenByField(currentField)
            if newToken and not newToken.touched and newToken ~= token then
                redirected = true
                movement:RedirectTo(newToken.position)
            end
        end
    end)

    local success, reason = movement:MoveTo(targetPos)
    return success

end

function TaskManager:doJumping()
    local playerHelper = self.bot.plr
    playerHelper:stopMoving()

    while self.bot.isRunning do
        local currentMonsterCount = self.bot.monsterHelper:getCloseMonsterCount()
        if currentMonsterCount == 0 then
            return true
        end

        local monster = self.bot.monsterHelper:getClosestMonster()
        local char = playerHelper.character
        local Configs = monster:FindFirstChild("Config")
        if char and Configs then
            local AttackRadius = Configs.AttackRadius.Value
            local root = playerHelper.rootPart
            local humanoid = playerHelper.humanoid
            local monsterRoot = monster and monster.PrimaryPart

            if root and humanoid and monsterRoot then
                local offset = monsterRoot.Position - root.Position
                local horizontalOffset = Vector3.new(offset.X, 0, offset.Z)
                local distance = horizontalOffset.Magnitude

                if distance <= AttackRadius then
                    local escapeDir = -horizontalOffset.Unit
                    local escapePos = root.Position + escapeDir * 5

                    -- Teleporting a test part to visualize might help debug
                    humanoid:MoveTo(escapePos)

                    -- Wait for the bot to complete movement or timeout
                    humanoid.MoveToFinished:Wait()
                end

                humanoid.Jump = true
            end
        end

        task.wait(1.25)
    end

    return true
end

function TaskManager:getSprinklerPositions(field, sprinklerData)
    local positions = {}
    if not field or not sprinklerData then return positions end

    local center = field.Position
    local count = sprinklerData.count
    local radius = sprinklerData.radius * 2
    local fieldSize = field.Size or Vector3.new(50, 0, 50)

    -- เช็คว่า field กว้างทางแกน X หรือ Z
    local isWideX = fieldSize.X > fieldSize.Z
    local isWideZ = fieldSize.Z > fieldSize.X

    -- คำนวณระยะห่างแบบปรับเองได้ ถ้าไม่มีให้ fallback เป็น radius
    local maxSpacing = math.min(fieldSize.X, fieldSize.Z) * 0.9
    local spacing = math.min(radius * 1.5, maxSpacing)
    

    if count == 1 then
        table.insert(positions, center)

    elseif count == 2 then
        if isWideX then
            table.insert(positions, center + Vector3.new(-spacing/2, 0, 0))
            table.insert(positions, center + Vector3.new(spacing/2, 0, 0))
        elseif isWideZ then
            table.insert(positions, center + Vector3.new(0, 0, -spacing/2))
            table.insert(positions, center + Vector3.new(0, 0, spacing/2))
        else
            table.insert(positions, center + Vector3.new(-spacing/2, 0, 0))
            table.insert(positions, center + Vector3.new(spacing/2, 0, 0))
        end

    elseif count == 3 then
        if isWideX then
            table.insert(positions, center + Vector3.new(-spacing, 0, 0))
            table.insert(positions, center)
            table.insert(positions, center + Vector3.new(spacing, 0, 0))
        elseif isWideZ then
            table.insert(positions, center + Vector3.new(0, 0, -spacing))
            table.insert(positions, center)
            table.insert(positions, center + Vector3.new(0, 0, spacing))
        else
            table.insert(positions, center + Vector3.new(0, 0, -spacing/2))
            table.insert(positions, center + Vector3.new(-spacing/2, 0, spacing/2))
            table.insert(positions, center + Vector3.new(spacing/2, 0, spacing/2))
        end

    elseif count == 4 then
        table.insert(positions, center + Vector3.new(-spacing/2, 0, -spacing/2))
        table.insert(positions, center + Vector3.new(spacing/2, 0, -spacing/2))
        table.insert(positions, center + Vector3.new(-spacing/2, 0, spacing/2))
        table.insert(positions, center + Vector3.new(spacing/2, 0, spacing/2))
    end

    return positions
end

function TaskManager:doPlaceSprinkler(field, sprinklerData)
    local playerHelper = self.bot.plr
    local humanoid = playerHelper.humanoid
    local positions = self:getSprinklerPositions(field, sprinklerData)
    local maxToPlace = sprinklerData.count
    self.sprinkler.placedCount = 0
    self.sprinkler.field = nil


    local function getDistanceFromField()
        if not playerHelper.rootPart or not field then return nil end

        local origin = playerHelper.rootPart.Position
        local direction = Vector3.new(0, -100, 0)

        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {field}
        params.FilterType = Enum.RaycastFilterType.Include

        local result = workspace:Raycast(origin, direction, params)

        if result and result.Instance == field then
            return (origin - result.Position).Magnitude
        end

        return nil 
    end

    local function waitUntilNearGround()
        while humanoid.FloorMaterial == Enum.Material.Air and humanoid.Parent do
            local distance = getDistanceFromField()
            if distance and distance <= 7 then
                return true
            end
            task.wait()
        end
        return false
    end


    for _, pos in ipairs(positions) do
        if self.sprinkler.placedCount >= maxToPlace then break end
        if not playerHelper:isValid() or not self.bot.isRunning then break end

        local playerHelper = shared.Helpers.Player
        local movement = MovementModule.new(playerHelper.humanoid)
        local success, reason = movement:MoveTo(pos)

        if not success then 
            warn(reason)
            continue
        end

        if self.sprinkler.placedCount >= 1 then
            humanoid.Jump = true
            task.wait(0.25)

            while humanoid.FloorMaterial ~= Enum.Material.Air and humanoid.Parent and self.bot.isRunning do
                task.wait()
            end

            if waitUntilNearGround() then
                placeSprinklerEvent:FireServer({ Name = "Sprinkler Builder" })
                self.sprinkler.placedCount += 1
            end
        else
            placeSprinklerEvent:FireServer({ Name = "Sprinkler Builder" })
            self.sprinkler.placedCount += 1
            self.sprinkler.field = field
        end
      
        task.wait(1)
    end

    return true
end
function TaskManager:doFarming(currentField)
    local playerHelper = self.bot.plr
    local sprout, sproutHealth = self:hasSprout()
    if sprout and shared.main.auto.autoFarmSprout and sproutHealth > 0 then
        local field = shared.Helpers.Field:getFieldByPosition(sprout.Position)
        if field then return self:doSprout(sprout, field) end
    end

    if not self.bot.plr:isPlayerInField(currentField) then
        self:returnToField(currentField.Position)
    end

    local sprinklerData = playerHelper:getSprinkler()
    if self:shouldPlaceSprinkler(currentField, sprinklerData) then
        self:doPlaceSprinkler(currentField, sprinklerData)
    end
  
    self:farming(currentField)
end

function TaskManager:doUseToy(toyName)
    local thread = coroutine.running()
    local playerHelper = self.bot.plr
    local clockPos = Vector3.new(330.5519104003906, 48.43824005126953, 191.44041442871094)
    local tweenResult, msg = playerHelper:tweenTo(clockPos, 1, function()
        task.wait(1)
        
        for _, state in ipairs({true, false}) do
            Services.VirtualInputManager:SendKeyEvent(state, Enum.KeyCode.E, false, game)
        end
        
        task.wait(1)
        self.bot.Toys.clock = false
        return coroutine.resume(thread, true)
    end)
    if not tweenResult then
        warn("tween fail while using toy: ", msg)
        return coroutine.resume(thread, false)
    end
    return coroutine.yield()
end

function TaskManager:convertPollen()
    local player = self.bot.plr
    if not player:isCapacityFull() then
        return false,'Backpack is not full'
    end

    local bot = self.bot
    local Hive = shared.Helpers.Hive
    local thread = coroutine.running()

    if shared.main.auto.autoHoneyMask then
        player:equipMask("Honey Mask")
    end

    local function shouldContinueConverting()
        if not shared.main.autoConvertBalloon then
            return player.Pollen > 0
        end

        local balloonValue, balloonBlessing = Hive:getBalloonData()
        balloonValue = balloonValue or 0
        balloonBlessing = balloonBlessing or 0
        return player.Pollen > 0 or (balloonValue > 0 and balloonBlessing >= (shared.main.convertAtBlessing or 1))
    end

    local convertButton = player.gameGUi.ActivateButton
    local convertEvent =  Services.ReplicatedStorage.Events.PlayerHiveCommand
    local result,msg =  player:tweenTo(Hive:getHivePosition(), 1, function()
        if not bot.isRunning then
            warn("bot is not running")
            return coroutine.resume(thread, false)
        end
        task.wait(.25)
        player:disableWalking(true)
        convertEvent:FireServer("ToggleHoneyMaking") -- trigger convert event

        local startTime = tick()
        local timeout = 300

        task.wait(.5)
        while shouldContinueConverting() and bot.isRunning and (tick() - startTime < timeout) and bot.state == bot.State.Convert do
            task.wait(.5)

            if convertButton and convertButton.BackgroundColor3 ~= Color3.fromRGB(201, 39, 28) and player.Pollen > 0 then
                convertEvent:FireServer("ToggleHoneyMaking")
            end
        end

        player:disableWalking(false)

        if bot.isRunning then task.wait(4) end

        player:equipMask()
        return coroutine.resume(thread, true)
    end)
    if not result then
        warn("Tween failed: ", msg)
        return coroutine.resume(thread, false)
    end
    return coroutine.yield()
end
function TaskManager:getSproutAmount(sprout)
    local function cleanNumberString(str)
        local cleaned = str
            :gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
                return c:match("^[%z\1-\127]$") and c or ""
            end)
            :gsub(",", "")
        return tonumber(cleaned)
    end

    local GuiPos = sprout:FindFirstChild("GuiPos")
    if not GuiPos then return 0 end
    local Gui = GuiPos.Gui
    local Frame = Gui.Frame
    local TextLabel = Frame.TextLabel
    return cleanNumberString(TextLabel.Text)

end
function TaskManager:hasSprout()
    if not shared.main.auto.autoFarmSprout then
        return nil, 0
    end
    local SproutsFolder = workspace.Sprouts
    local bestSprout = nil
    local highestAmount = -math.huge

    for index, Sprout in pairs(SproutsFolder:GetChildren()) do

        if Sprout and Sprout:FindFirstChild("GrowthStep") then
            local amount = self:getSproutAmount(Sprout)
            if amount and amount > highestAmount then
                highestAmount = amount
                bestSprout = Sprout
            end
        end
    end
    if not bestSprout then
        return nil, 0
    end
    return bestSprout, highestAmount
end
function TaskManager:shouldPlaceSprinkler(field, sprinklerData)
    return sprinklerData and shared.main.auto.autoSprinkler and self.sprinkler.field ~= field
end
return TaskManager