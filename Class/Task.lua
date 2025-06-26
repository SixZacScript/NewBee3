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
    self.placedField = nil
    self.connections = {}

    return self
end

function TaskManager:returnToField(data)
    if not data.Position then return warn('Failed returnToField becuz Position is nil') end
    if not data.Player then return warn('Failed returnToField player not found') end

    local player = data.Player
    local fieldPosition = data.Position + Vector3.new(0, 4, 0)
    local thread = coroutine.running()

    local result, msg = player:tweenTo(fieldPosition, 1, function()
        task.wait(.5)
        
        if data.Callback and typeof(data.Callback) == "function" then data.Callback() end
        coroutine.resume(thread, true)
    end)
    if not result then
        warn("Failed to tween character", msg)
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
        self:returnToField({ Position = field.Position, Player = player })
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
    options = options and options or {}
    local startTime = os.clock()
    local waitTime = options.waitTime or 15
    
    while os.clock() - startTime < waitTime and self.bot.isRunning and shared.main.auto.autoFarmSprout do
        self:farming(field, options)
        task.wait()
    end
end

function TaskManager:farming(currentField , options)
    if not self.bot.isRunning then
        return false 
    end

    if self.connections.tokenRunService then
        self.connections.tokenRunService:Disconnect()
        self.connections.tokenRunService = nil
    end
    
    local token = self.bot.tokenHelper:getBestTokenByField(currentField, options)
    local targetPos = (token and not token.touched) and token.position or self.bot.Field:getRandomFieldPosition(currentField)
    
    -- Check monster count before starting movement
    local monsterCount = self.bot.monsterHelper:getCloseMonsterCount()
    if monsterCount > 0 then
        self:doJumping()
    end
    
    -- Cleanup method to avoid code duplication
    local function cleanup(shouldBreak)
        if self.connections.tokenRunService then
            self.connections.tokenRunService:Disconnect()
            self.connections.tokenRunService = nil
        end
        if shouldBreak then shouldBreak() end
    end
    
    self.bot:moveTo(targetPos, {
        onBreak = function(shouldBreak)
            local runService = game:GetService("RunService")
            self.connections.tokenRunService = runService.Heartbeat:Connect(function()
                -- Check monster count in runService
                local currentMonsterCount = self.bot.monsterHelper:getCloseMonsterCount()
                if currentMonsterCount > 0 then
                    self:doJumping()
                    cleanup(shouldBreak)
                    return
                end
                
                local newToken = self.bot.tokenHelper:getBestTokenByField(currentField)
                if newToken and not newToken.touched and newToken ~= token or not self.bot.isRunning then
                    cleanup(shouldBreak)
                end
            end)
            
            return self.connections.tokenRunService
        end,
    })
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

        if char then
            local root = playerHelper.rootPart
            local humanoid = playerHelper.humanoid
            local monsterRoot = monster and monster.PrimaryPart

            if root and humanoid and monsterRoot then
                local offset = monsterRoot.Position - root.Position
                local horizontalOffset = Vector3.new(offset.X, 0, offset.Z)
                local distance = horizontalOffset.Magnitude

                if distance <= 20 then
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


function TaskManager:doFarming(currentField)
    if self.connections.tokenRunService then
        self.connections.tokenRunService:Disconnect()
        self.connections.tokenRunService = nil
    end

    local sprout, sproutHealth = self:hasSprout()
    if sprout and shared.main.auto.autoFarmSprout and sproutHealth > 0 then
        local field = shared.Helpers.Field:getFieldByPosition(sprout.Position)
        if field then return self:doSprout(sprout, field) end
    end

    if not self.bot.plr:isPlayerInField(currentField) then
        self:returnToField({Player = self.bot.plr, Position = currentField.Position})
    end

  
    self:farming(currentField)
end

function TaskManager:convertPollen()
    local player = self.bot.plr
    if not player:isCapacityFull() then
        return false
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
    player:tweenTo(Hive:getHivePosition(), 1, function()
        if not bot.isRunning then
            warn("bot is not running")
            return coroutine.resume(thread, false)
        end

        player:disableWalking(true)
        convertEvent:FireServer("ToggleHoneyMaking") -- trigger convert event

        local startTime = tick()
        local timeout = 300

        while shouldContinueConverting() and bot.isRunning and (tick() - startTime < timeout) and bot.state == bot.State.Convert do
            task.wait(.5)

            if convertButton and convertButton.BackgroundColor3 ~= Color3.fromRGB(201, 39, 28) and player.Pollen > 0 then
                convertEvent:FireServer("ToggleHoneyMaking")
            end
        end

        player:disableWalking(false)

        if bot.isRunning then task.wait(4) end

        player:equipMask()
        coroutine.resume(thread, true)
    end)

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
return TaskManager