return {
    auto = {
        autoFarm = false,
        autoDig = false,
        autoSprinkler = false,
        autoPlanter = false,
        autoFarmSprout = false,
        autoHoneyMask = false,
        autoClock = false,
    },
    farm = {
        farmBubble = false,
        ignoreHoneyToken = false,
        priorityTokens = {},
    },
    Planter = {
        Slots = {
            {
                PlanterType = "None",
                Field = nil,
                HarvestAt = 100,
                Placed = false,
            },
            {
                PlanterType = "None",
                Field = nil,
                HarvestAt = 100,
                Placed = false,
            },
            {
                PlanterType = "None",
                Field = nil,
                HarvestAt = 100,
                Placed = false,
            }
        },
        Actives = {}
    },
    Equip = {
        defaultMask = nil
    },
    Quest = {
        enabledNPCs = {},
        bestWhiteField = nil,
        bestBlueField = nil,
        bestRedField = nil,
    },
    hideDecorations = false,
    WalkSpeed = 70,
    JumpPower = 80,
}