local Rep = game:GetService("ReplicatedStorage")
local Events = Rep.Events

local TokenDataModule = shared.ModuleLoader:load('Data/Token.lua')
local TokenCreator = shared.ModuleLoader:load('Class/TokenCreator.lua')

local TokenHelper = {}
TokenHelper.__index = TokenHelper

function TokenHelper:new()
    local self = setmetatable({}, TokenHelper)
    self.activeTokens = {}
    self.connections = {}

    task.spawn(function()
        repeat
            task.wait()
        until shared.Helpers.Field
        self:setupBubbleHandling()
        self:setupTokenHandling()
    end)
    return self
end

function TokenHelper:setupBubbleHandling()
    local Event = Rep.Events.LocalFX
    
    self.connections.AddedBubble = Event.OnClientEvent:Connect(function(type, data)
        if type == "Bubble" and data.Action == "Spawn" then
            self:handleAddedToken(data, 'Bubble')
        elseif type == "Bubble" and data.Action == "Pop" then
            self:removeToken(data.ID)
        end
    end)
end

function TokenHelper:setupTokenHandling()
    self.connections.AddedToken = Events.CollectibleEvent.OnClientEvent:Connect(function(action, tokenParams)
        if action == "Spawn" then
            self:handleAddedToken(tokenParams)
        elseif action == "Collect" then
            self:removeToken(tokenParams.ID)
        end
    end)
end
function TokenHelper:handleAddedToken(tokenParams, tokenType)
    local position = tokenParams.Pos
    local serverID = tokenParams.ID
    local duration = tokenParams.Dur or 4
    local icon = tokenParams.Icon or nil
    local name = "Unknow"
    local tokenData = {}

    if not tokenType  then
        local assetID = self:extractAssetID(icon)
        name, tokenData = TokenDataModule:getTokenById(assetID)
    else
        duration = 4
        name = tokenType
        tokenData.isSkill = false
    end


    local simPart = TokenCreator:createSimPart(position, name)
    local newToken = TokenCreator.new(tokenData.id, name, simPart, tokenData.isSkill, position)

    local allFieldParts = shared.Helpers.Field:getAllFieldParts()
    for index, fieldPart in pairs(allFieldParts) do
        local isInBound = self:isPositionInBounds(position, fieldPart)
        if isInBound then
            newToken.tokenField = fieldPart
        end
    end

    task.delay(duration, function()
        self:removeToken(serverID)
    end)
    self.activeTokens[serverID] = newToken
end

function TokenHelper:getBestTokenByField(targetField, option)
    local player = shared.Helpers.Player
    if not player:isValid() or not player.rootPart or not targetField then 
        return nil
    end

    option = option or {}
    local ignoreSkill = option.ignoreSkill or false
    local ignoreHoneyToken = shared.main.farm.ignoreHoneyToken or false
    local playerRoot = player.rootPart
    local bestToken = nil
    local shortestDistance = math.huge

    for _, tokenData in pairs(self.activeTokens) do
        if tokenData.touched or not tokenData.position or not tokenData.tokenField then
            continue
        end
        if tokenData.tokenField ~= targetField then
            continue
        end

        if (tokenData.isSkill and ignoreSkill) then
            continue
        end
        if (ignoreHoneyToken and tokenData.id == 1472135114) then
            continue
        end
        if (not shared.main.farm.farmBubble and tokenData.name == "Bubble") then
            continue
        end

        local distance = self:calculateDistance(tokenData, playerRoot)
        if distance and distance < shortestDistance then
            shortestDistance = distance
            bestToken = tokenData
        end
    end

    return bestToken
end

function TokenHelper:calculateDistance(tokenData, playerRoot)
    if not tokenData or not tokenData.position or not playerRoot or not playerRoot.Position then
        return math.huge
    end
    
    return (tokenData.position - playerRoot.Position).Magnitude
end

function TokenHelper:removeToken(tokenServerID)
    local token = self.activeTokens[tokenServerID]
    if token then
        token:cleanup()
        self.activeTokens[tokenServerID] = nil
    end
end

function TokenHelper:extractAssetID(url)
    if not url then return nil end
    local id = string.match(url, "rbxassetid://(%d+)") or string.match(url, "[&?]id=(%d+)")
    return tonumber(id)
end

function TokenHelper:isPositionInBounds(position, field)
    if not field then return false end

    local size = field.Size
    local center = field.Position

    local min = center - size / 2
    local max = center + size / 2

    return (
        position.X >= min.X and position.X <= max.X and
        position.Z >= min.Z and position.Z <= max.Z
    )
end

return TokenHelper