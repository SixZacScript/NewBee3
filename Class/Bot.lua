local RunService = game:GetService("RunService")
local TaskManager = shared.ModuleLoader:load('Class/Task.lua')
local MonsterHelper = shared.ModuleLoader:load('Class/Monster.lua')


local Bot = {}
Bot.__index = Bot

-- State Constants
Bot.State = {
    Convert = "Convert",
    PLANTER = "Do planter",
    USE_TOYS = "Use toy",
    FARM = "Farm",
    IDLE = "Idle",
}

function Bot.new()
    local self = setmetatable({}, Bot)
    
    self.state = Bot.State.IDLE
    self.isRunning = false
    self.connections = {}

    
    -- Initialize helper modules
    self.Field = shared.Helpers.Field
    self.plr = shared.Helpers.Player
    self.tokenHelper = shared.Helpers.Token
    self.botGui = shared.Helpers.Gui
    self.taskManager = TaskManager.new(self)
    self.monsterHelper = MonsterHelper.new()

    self.currentField = self.Field:getField()
    self.Toys = {
        clock = false,
    }

    self.startTime = os.time()
    self:setupTimer()
    return self
end

function Bot:getUptimeString()
    local elapsed = os.time() - self.startTime

    local days = math.floor(elapsed / 86400)
    local hours = math.floor((elapsed % 86400) / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = elapsed % 60

    local parts = {}
    if days > 0 then table.insert(parts, days .. "d") end
    if hours > 0 then table.insert(parts, hours .. "h") end
    if minutes > 0 then table.insert(parts, minutes .. "m") end
    table.insert(parts, seconds .. "s")

    return table.concat(parts, " ")
end

function Bot:setupTimer()
    local lastClockTime = os.time()

    task.spawn(function()
        while true do
            task.wait(1)
            if os.time() - lastClockTime >= 3615 then
                self.Toys.clock = true
                lastClockTime = os.time()
            end
        end
    end)
end

function Bot:realtimeCheck()
    if self.connections.realtime then
        self.connections.realtime:Disconnect()
        self.connections.realtime = nil
    end

    self.connections.realtime = RunService.Heartbeat:Connect(function(deltaTime)
        if self.state == Bot.State.FARM or self.state == Bot.State.Idle  then
            if self.currentField ~= self.Field:getField() then
                self.currentField = self.Field:getField()
            end
        end
    end)
end

function Bot:start()
    if self.isRunning then 
        print("[Bot] Already running!")
        return 
    end
    
    self.isRunning = true

    self:realtimeCheck()
    while self.isRunning do
        self:evaluateState()
        self:executeState()
        task.wait() 
    end
end

function Bot:stop()
    self.isRunning = false
    self.state = Bot.State.IDLE
    self.plr:stopMoving()
    self:cleanup()
    self.botGui:updateStatus('Stop')
end

function Bot:evaluateState()
    if self.plr:isCapacityFull() then
        self.state = Bot.State.Convert
    elseif self:shouldDoPlanter() then
        self.state = Bot.State.PLANTER
    elseif self:shouldUseToy() then
        self.state = Bot.State.USE_TOYS
    else
        self.state = Bot.State.FARM
    end
    self.botGui:updateStatus(self.state)
end

function Bot:executeState()
    if self.state == Bot.State.Convert then
        self.taskManager:convertPollen()
    elseif self.state == Bot.State.PLANTER then
        self:handlePlanter()
    elseif self.state == Bot.State.USE_TOYS then
        self:handleUseToys()
    elseif self.state == Bot.State.FARM then
        self.taskManager:doFarming(self.currentField)
    else
        warn("[Bot] Unknown state:", self.state)
        self.state = Bot.State.IDLE
    end
end

function Bot:handleUseToys()
    local selectedToy, selectedToyName
    for toyName, toy in pairs(self.Toys) do
        if toy == true then
            selectedToy = toy
            selectedToyName = toyName
            break
        end
    end

    self.taskManager:doUseToy(selectedToyName)
    return true
end
function Bot:handlePlanter()
    local playerHelper = self.plr
    local planterToPlace = playerHelper:getPlanterToPlace()
    local planterToHarvest = playerHelper:getCanHarvestPlanter()

    if planterToPlace then
        return self.taskManager:placePlanter()
    elseif planterToHarvest then
        return self.taskManager:harvestPlanter(planterToHarvest)
    end 

    return true
end



function Bot:moveTo(targetPosition, options)
    options = options or {}
    
    if not self.plr:isValid() then 
        return false, "Movement validation failed"
    end
    
    -- Check if already close to target
    local currentPos = self.plr.rootPart.Position
    if (currentPos - targetPosition).Magnitude < 3 then
        return true
    end
    
    local humanoid = self.plr.humanoid
    local timeout = options.timeout or 3
    
    humanoid:MoveTo(targetPosition)
    
    return self:waitForMovement(timeout, options.onBreak)
end

function Bot:waitForMovement(timeout, onBreak)
    local startTime = tick()
    local finished = false
    local broken = false
    local connections = {}
    
    -- Movement completion handler
    local humanoid = self.plr.humanoid
    connections.move = humanoid.MoveToFinished:Connect(function(reached)
        finished = reached
    end)
    
    local function cleanupConnections(connections)
        for key, conn in pairs(connections) do
            if conn and typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
            connections[key] = nil -- FIX: Clear the reference
        end
    end
    if onBreak and type(onBreak) == "function" then
        -- FIX: Store the returned connection properly
        local breakConnection = onBreak(function()
            broken = true
        end)
        -- FIX: Only store if it's actually a connection
        if breakConnection and typeof(breakConnection) == "RBXScriptConnection" then
            connections.breakConn = breakConnection
        end
    end
    
    -- Main wait loop
    while not finished and not broken do
        -- FIX: Check if bot is still running
        if not self.isRunning then
            cleanupConnections(connections)
            self.plr:stopMoving() -- Stop the humanoid movement
            return false
        end
        
        if tick() - startTime > timeout then
            cleanupConnections(connections)
            self.plr:stopMoving() -- Stop movement on timeout
            warn("⏱️ MoveTo timeout")
            return true
        end
        
        if not self.plr:isValid() then
            cleanupConnections(connections)
            self.plr:stopMoving() -- Stop movement if player invalid
            warn("Player became invalid during movement")
            return true
        end
        
        task.wait()
    end
    
    cleanupConnections(connections)
    return true
end

function Bot:cleanup()
    for key, conn in pairs(self.connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
        self.connections[key] = nil 
    end
end
function Bot:shouldUseToy()
    for toyName, toy in pairs(self.Toys) do
        if toy == true then
            if toyName == "clock" and not shared.main.auto.autoClock then
                continue
            end
            return toy
        end
    end
   return false 
end
function Bot:shouldDoPlanter()
    if not shared.main.auto.autoPlanter then return false end

    local playerHelper = shared.Helpers.Player
    local canHarvestPlanter = playerHelper:getCanHarvestPlanter()
    local planterToPlace = playerHelper:getPlanterToPlace()

    return canHarvestPlanter or planterToPlace
end

function Bot:destroy()
    print("[Bot] Destroying bot...")
    self:stop()
    
    -- FIX: More thorough cleanup
    if self.tokenHelper and self.tokenHelper.destroy then
        self.tokenHelper:destroy()
    end
    

    
    -- Clean up all references
    self.Field = nil
    self.plr = nil
    self.currentField = nil
    self.tokenHelper = nil
    self.taskManager = nil
    self.connections = nil
end

return Bot