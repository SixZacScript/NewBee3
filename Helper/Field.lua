local WP = game:GetService('Workspace')
local FlowerZones = WP:FindFirstChild('FlowerZones')

local FieldHelper = {}
FieldHelper.__index = FieldHelper

local FIELD_TYPE = {
    WHITE = "White",
    RED = "Red",
    BLUE = "Blue",
}
local FIELD_TYPE_ORDER = {FIELD_TYPE.WHITE, FIELD_TYPE.BLUE, FIELD_TYPE.RED}
local RANDOM_POS_CONFIG = {
    PADDING = 15,
    MIN_DISTANCE = 15,
    MAX_DISTANCE = 50,
    MAX_DISTANCE_FROM_CENTER = 30,
    MAX_ATTEMPTS = 50,
    FALLBACK_DISTANCE = 10,
    MIN_FALLBACK_DISTANCE = 3,
    SAFE_MOVE_DISTANCE = 3,
    ANGLE_STEP = 30
}
function FieldHelper:new()
    local self = setmetatable({}, FieldHelper)
    self.displayNameToFieldMap = {}
    self.fieldMap = {}
    self.fields = {
        {name = "Sunflower Field", emoji = "🌻", type = FIELD_TYPE.WHITE, bestField = false},
        {name = "Dandelion Field", emoji = "🌼", type = FIELD_TYPE.WHITE, bestField = true},
        {name = "Mushroom Field", emoji = "🍄", type = FIELD_TYPE.RED, bestField = true},
        {name = "Clover Field", emoji = "☘️", type = FIELD_TYPE.BLUE, bestField = false},
        {name = "Blue Flower Field", emoji = "💠", type = FIELD_TYPE.BLUE, bestField = true},
        {name = "Spider Field", emoji = "🕷️", type = FIELD_TYPE.WHITE, bestField = false},
        {name = "Strawberry Field", emoji = "🍓", type = FIELD_TYPE.RED, bestField = false},
        {name = "Bamboo Field", emoji = "🎍", type = FIELD_TYPE.BLUE, bestField = false},
        {name = "Pineapple Patch", emoji = "🍍", type = FIELD_TYPE.WHITE, bestField = false},
        {name = "Pumpkin Patch", emoji = "🎃", type = FIELD_TYPE.WHITE, bestField = false},
        {name = "Cactus Field", emoji = "🌵", type = FIELD_TYPE.RED, bestField = false},
        {name = "Pine Tree Forest", emoji = "🌳", type = FIELD_TYPE.BLUE, bestField = false},
        {name = "Ant Field", emoji = "🐜", type = FIELD_TYPE.RED, bestField = false},
        {name = "Rose Field", emoji = "🌹", type = FIELD_TYPE.RED, bestField = false},
        {name = "Stump Field", emoji = "🐌", type = FIELD_TYPE.BLUE, bestField = false},
        {name = "Mountain Top Field", emoji = "⛰️", type = FIELD_TYPE.BLUE, bestField = false},
        {name = "Coconut Field", emoji = "🌴", type = FIELD_TYPE.WHITE, bestField = false},
        {name = "Pepper Patch", emoji = "🌶️", type = FIELD_TYPE.RED, bestField = false},
    }
    for i, field in ipairs(self.fields) do
        local displayName = field.emoji .. field.name
        
        self.fieldMap[field.name] = {
            emoji = field.emoji, 
            type = field.type, 
            index = i
        }
        self.displayNameToFieldMap[displayName] = field.name
    end

    self.currentField = "Sunflower Field"
    self.fieldPart = FlowerZones:FindFirstChild("Sunflower Field")
    
    return self
end

function FieldHelper:getField(fieldName)
    return FlowerZones:FindFirstChild(fieldName or self.currentField)
end

function FieldHelper:getAllFieldDisplayNames()
    local displayNames = {}
    for _, field in ipairs(self.fields) do
        displayNames[#displayNames + 1] = field.emoji .. field.name
    end
    return displayNames
end

function FieldHelper:getRandomFieldPosition(targetField)
    local player = shared.Helpers.Player
    if not targetField then 
        return player.rootPart.Position 
    end

    local config = RANDOM_POS_CONFIG
    local size, center = targetField.Size, targetField.Position

    local minX = center.X - size.X / 2 + config.PADDING
    local maxX = center.X + size.X / 2 - config.PADDING
    local minZ = center.Z - size.Z / 2 + config.PADDING
    local maxZ = center.Z + size.Z / 2 - config.PADDING
    local y = player.rootPart.Position.Y

    local randomX = math.random() * (maxX - minX) + minX
    local randomZ = math.random() * (maxZ - minZ) + minZ

    return Vector3.new(randomX, y, randomZ)
end

function FieldHelper:getAllFieldParts()
    local parts = {}
    for _, field in ipairs(self.fields) do
        local part = self:getField(field.name)
        if part then
            parts[#parts + 1] = part
        end
    end
    return parts
end

function FieldHelper:getOriginalFieldName(displayName)
    return self.displayNameToFieldMap[displayName]
end

function FieldHelper:getFieldByPosition(position)
    if not position then return nil end

    local closestField = nil
    local minDistance = math.huge

    for _, field in ipairs(self.fields) do
        local part = self:getField(field.name)
        if part and part:IsA("BasePart") then
            local distance = (part.Position - position).Magnitude
            if distance < minDistance then
                minDistance = distance
                closestField = part
            end
        end
    end

    return closestField
end

function FieldHelper:SetCurrentField(displayName)
    local fieldName = self:getOriginalFieldName(displayName)
    if fieldName then
        self.currentField = fieldName
        self.fieldPart = FlowerZones:FindFirstChild(fieldName)
        
        if shared.Bot then
            shared.Bot.currentField = self.fieldPart
        end
    end
    return self.currentField
end
return FieldHelper