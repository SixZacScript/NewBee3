local planterTab = {}
planterTab.__index = planterTab

function planterTab:load(FluentUI)
    local self = setmetatable({}, planterTab)
    self.FluentUI = FluentUI
    self.Fluent = FluentUI.Fluent
    self.Tab = FluentUI.Tabs.planter
    self.options = {}


    self:createContent()
    return self
end

function planterTab:createContent()
    local planterTab = self.Tab
    local PlanterConfig = shared.main.Planter
    local Slots = PlanterConfig.Slots

    self.options.autoPlanterToggle = planterTab:AddToggle("autoPlanterToggle", {
        Title = "Enable Auto Planters",
        Description = "Automatically manage planter placement and harvesting.",
        Default = shared.main.auto.autoPlanter or false,
        Callback = function(value)
            shared.main.auto.autoPlanter = value
        end
    })

    local activePlanterSection = planterTab:AddSection("Active Planters")
    self.options.activePlanterSlot1 = activePlanterSection:AddParagraph({
        Title = "Planter Slot 1",
        Content = "No planter is currently placed."
    })
    self.options.activePlanterSlot2 = activePlanterSection:AddParagraph({
        Title = "Planter Slot 2",
        Content = "No planter is currently placed."
    })
    self.options.activePlanterSlot3 = activePlanterSection:AddParagraph({
        Title = "Planter Slot 3",
        Content = "No planter is currently placed."
    })

    for i = 1, 3 do
        local section = planterTab:AddSection("Auto Planter Slot " .. i)
        self["autoPlanter" .. i] = section:AddDropdown("autoPlanter" .. i, {
            Title = "Select Planter Type",
            Values = {'None', "Paper", "Plastic", "Blue Clay", "Red Clay", "Candy", "Tacky", "Pesticide"},
            Multi = false,
            Default = 1,
            Callback = function(planter)
                Slots[i].PlanterType = planter
            end
        })

        self["autoPlanter" .. i .. "Field"] = section:AddDropdown("autoPlanter" .. i .. "Field", {
            Title = "Select Field",
            Values = shared.Helpers.Field:getAllFieldDisplayNames(),
            Multi = false,
            Default = 1,
            Callback = function(field)  
                Slots[i].Field = field
            end
        })

        self["autoPlanter" .. i .. "HarvestAt"] = section:AddSlider("autoPlanter" .. i .. "HarvestAt", {
            Title = "Harvest At %",
            Default = Slots[i].HarvestAt or 100,
            Min = 1,
            Max = 100,
            Rounding = 0,
            Callback = function(value)
                Slots[i].HarvestAt = tonumber(value)
            end
        })
    end
    
end


return planterTab