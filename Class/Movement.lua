-- MovementModule.lua
local MovementModule = {}
MovementModule.__index = MovementModule

local RunService = game:GetService("RunService")

-- Constructor
function MovementModule.new(humanoid)
    local self = setmetatable({}, MovementModule)
    
    self.humanoid = humanoid
    self.character = humanoid.Parent
    self.distanceThreshold = 5 -- studs to consider "reached"
    self.stuckThreshold = 3 -- seconds before considering stuck
    
    -- Callbacks
    self.onFinished = nil
    self.onFailed = nil
    self.onStep = nil
    
    return self
end

-- Synchronous move to target position (blocks until complete)
function MovementModule:MoveTo(targetPosition)
    if not self.humanoid or not self.humanoid.Parent then
        if self.onFailed then
            self.onFailed("Humanoid is invalid or destroyed")
        end
        return false, "Humanoid is invalid or destroyed"
    end
    
    local success = false
    local failureReason = nil
    local isComplete = false
    self.shouldStop = false

    
    -- Variables for tracking movement
    local lastPosition = self.character.HumanoidRootPart.Position
    local stuckTimer = 0
    local stepConnection = nil
    local reachedConnection = nil
    
    -- Start the movement
    self.humanoid:MoveTo(targetPosition)
    
    -- Set up step callback
    if self.onStep then
        stepConnection = RunService.Heartbeat:Connect(function()
            if isComplete or self.shouldStop then return end
            
            local currentPosition = self.character.HumanoidRootPart.Position
            self.onStep(currentPosition)
        end)
    end
    
    -- Handle MoveToFinished event
    local moveToConnection = self.humanoid.MoveToFinished:Connect(function(reached)
        if not isComplete and not self.shouldStop then
            isComplete = true
            success = reached
            if not reached then
                failureReason = "Humanoid could not reach target"
            end
        end
    end)
    
    -- Set up movement monitoring
    reachedConnection = RunService.Heartbeat:Connect(function()
        if isComplete or self.shouldStop then return end
        
        local currentPosition = self.character.HumanoidRootPart.Position
        local distanceToTarget = (currentPosition - targetPosition).Magnitude
        
        -- Check if reached target
        if distanceToTarget <= self.distanceThreshold then
            isComplete = true
            success = true
            return
        end
        
        -- Check if stuck (not moving for too long)
        local distanceMoved = (currentPosition - lastPosition).Magnitude
        if distanceMoved < 0.1 then -- barely moved
            stuckTimer = stuckTimer + task.wait()
            if stuckTimer >= self.stuckThreshold then
                isComplete = true
                success = false
                failureReason = "Character appears to be stuck"
                return
            end
        else
            stuckTimer = 0
            lastPosition = currentPosition
        end
    end)
    
    -- Wait for completion
    while not isComplete and not self.shouldStop do
        task.wait()
    end

    if self.shouldStop then
        isComplete = true
        success = false
        failureReason = "Movement stopped"
    end
    
    -- Cleanup connections
    moveToConnection:Disconnect()
    if stepConnection then
        stepConnection:Disconnect()
    end
    if reachedConnection then
        reachedConnection:Disconnect()
    end
    
    -- Call appropriate callback
    if success then
        if self.onFinished then
            self.onFinished()
        end
    else
        if self.onFailed then
            self.onFailed(failureReason)
        end
    end
    
    return success, failureReason
end

-- Redirect method
function MovementModule:RedirectTo(position)
    self:Stop()
    task.wait(0.05)
    return self:MoveTo(position)
end

function MovementModule:Stop()
    self.shouldStop = true
    if self.humanoid then
        self.humanoid:MoveTo(self.character.HumanoidRootPart.Position)
    end
end

-- Set callbacks
function MovementModule:SetOnFinished(callback)
    self.onFinished = callback
end

function MovementModule:SetOnFailed(callback)
    self.onFailed = callback
end

function MovementModule:SetOnStep(callback)
    self.onStep = callback
end

-- Configuration methods
function MovementModule:SetDistanceThreshold(distance)
    self.distanceThreshold = distance
end

function MovementModule:SetStuckThreshold(seconds)
    self.stuckThreshold = seconds
end

return MovementModule
