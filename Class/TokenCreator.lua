local Players = game:GetService("Players")

local Token = {}
Token.__index = Token

function Token.new(id, name, instance, isSkill, position)
    local self = setmetatable({
        id = id or 0,
        name = name or "Unknown",
        instance = instance,
        isSkill = isSkill or false,
        position = position,
        touched = false,
        touchedBy = nil,
        tokenField = nil,
        spawnTime = tick(),
        cleanupScheduled = false,
        connections = {},
    }, Token)

    if instance then
        self:setupTouchHandler()
    end

    return self
end

function Token:setupTouchHandler()
    if not self.instance then return end

    local conn = self.instance.Touched:Connect(function(hit)
        self:onTouched(hit)
    end)

    table.insert(self.connections, conn)
end

function Token:onTouched(hit)
    local character = hit and hit.Parent
    if character then
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            self.touchedBy = player.UserId
            self.touched = true
        end
    end

    if not self.cleanupScheduled then
        self.cleanupScheduled = true
        task.delay(1, function()
            if self.instance and self.instance:IsDescendantOf(workspace) then
                self.touched = false
            end
            self.cleanupScheduled = false
        end)
    end
end

function Token:cleanup()
    -- Disconnect signals
    for i, conn in ipairs(self.connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
        self.connections[i] = nil
    end
    self.connections = nil

    -- Destroy instance
    if self.instance and self.instance.Destroy then
        self.instance:Destroy()
    end
    self.instance = nil

    -- Clear all strong references
    self.position = nil
    self.touchedBy = nil
    self.tokenField = nil
    self.cleanupScheduled = nil
end

function Token:createSimPart(position, name)
    local isBubble = name == "Bubble"
    local simToken = Instance.new("Part")
    simToken.Size = isBubble and  Vector3.new(10,10,10) or  Vector3.new(3,3,3)
    simToken.Position = position
    simToken.Anchored = true
    simToken.CanTouch = true
    simToken.CanCollide = false
    simToken.Shape = isBubble and Enum.PartType.Ball or Enum.PartType.Ball 
    simToken.Transparency = 1
    simToken.Name = name or "Token"
    simToken.Parent = workspace.Terrain
    return simToken
end
return Token
