local VisibilityHider = {}

local hideList = {
    ['SpiderWeb'] = true,
    ['Decorations'] = true,
    ["FieldDecos"] = true,
    ['Invisible Walls'] = true,
    ["Map"] = {
        "Fences"
    },
}

local exceptList = {
    ['Decorations'] = {
        "Stump",
        "JumpGames",
        'StarAmuletBuilding',
        ["Misc"] = {
            "Mushroom",
            "EggMachine",
            'JellyMachine'
        },
    }
}

local originalProperties = {}

local function isInList(list, key)
    if type(list) == "table" then
        for _, v in ipairs(list) do
            if v == key then
                return true
            end
        end
    end
    return false
end

local function storeOriginalProperties(part)
    originalProperties[part] = {
        Transparency = part.Transparency,
        CastShadow = part.CastShadow,
        CanCollide = part.CanCollide,
        CanQuery = part.CanQuery,
        Decals = {}
    }
    for _, decal in ipairs(part:GetChildren()) do
        if decal:IsA("Decal") then
            table.insert(originalProperties[part].Decals, {
                decal = decal,
                Transparency = decal.Transparency
            })
        end
    end
end

local function hidePart(part)
    if part:IsA("BasePart") then
        if not originalProperties[part] then
            storeOriginalProperties(part)
        end
        part.Transparency = 1
        part.CastShadow = false
        part.CanCollide = false
        part.CanQuery = false
        for _, decal in ipairs(part:GetChildren()) do
            if decal:IsA("Decal") then
                decal.Transparency = 1
            end
        end
    end
end

local function hideSpecificColorParts(model, targetColor)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Color == targetColor then
            hidePart(descendant)
        end
    end
end

local function deepExcept(parent, excepts)
    for _, child in ipairs(parent:GetChildren()) do
        local childExcepts = excepts and excepts[child.Name]

        if isInList(excepts, child.Name) then
            if child.Name == "Mushroom" then
                hideSpecificColorParts(child, Color3.fromRGB(253, 234, 141))
            end
        elseif type(childExcepts) == "table" then
            deepExcept(child, childExcepts)
        else
            hidePart(child)  -- Hide the immediate child itself
            for _, descendant in ipairs(child:GetDescendants()) do
                hidePart(descendant)
            end
        end
    end
end

function VisibilityHider:Apply()
    for _, parent in ipairs(workspace:GetChildren()) do
        local parentName = parent.Name

        if hideList[parentName] == true then
            hidePart(parent)           -- Hide the parent itself
            deepExcept(parent, exceptList[parentName])

        elseif type(hideList[parentName]) == "table" then
            for _, child in ipairs(parent:GetChildren()) do
                if isInList(hideList[parentName], child.Name) then
                    if not (exceptList[parentName] and isInList(exceptList[parentName], child.Name)) then
                        hidePart(child)   -- Hide immediate child
                        for _, descendant in ipairs(child:GetDescendants()) do
                            hidePart(descendant)
                        end
                    end
                end
            end
        end
    end
end

function VisibilityHider:Restore()
    for part, props in pairs(originalProperties) do
        if part:IsA("BasePart") then
            part.Transparency = props.Transparency
            part.CastShadow = props.CastShadow
            part.CanCollide = props.CanCollide
            part.CanQuery = props.CanQuery
            for _, decalInfo in ipairs(props.Decals) do
                if decalInfo.decal then
                    decalInfo.decal.Transparency = decalInfo.Transparency
                end
            end
        end
    end
end

return VisibilityHider
