-- local Rep = game:GetService("ReplicatedStorage")
-- local HttpService = game:GetService("HttpService")
-- local UserInputService = game:GetService("UserInputService")
-- local QuestService = Rep:WaitForChild("Quests")

-- local QuestSystem = {}
-- QuestSystem.__index = QuestSystem

-- function QuestSystem.new()
--     local self = setmetatable({}, QuestSystem)
--     local success, result = pcall(function()
--         return require(QuestService)
--     end)
    
--     if not success then
--         warn("Failed to require QuestService. This might be a script context issue.")
--         warn("Error:", result)
--         warn("Make sure you're running this from the correct script type (LocalScript/ServerScript)")
--         return nil
--     end
    
--     self.QuestService = result

--     UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
--         if gameProcessedEvent then return end

--         if input.KeyCode == Enum.KeyCode.Y then
--             local activeQuests = self:getActiveQUests()
--             print("Active Quests:", activeQuests)
--         end
--     end)

--     self:initializeAllQuests()
--     return self
-- end

-- function QuestSystem:initializeAllQuests()
--     local fileName = "beeSwarmData/allQuest.json"
--     local allQuests

--     if isfile(fileName) then
--         local data = readfile(fileName)
--         allQuests = HttpService:JSONDecode(data)
--     else
--         allQuests = self.QuestService:GetAllQuests()
--         local json = HttpService:JSONEncode(allQuests)
--         writefile(fileName, json)
--     end

--     self.allQuests = allQuests
-- end

-- function QuestSystem:getActiveQUests()
--     local actives = {}
--     local plrStats = shared.Helpers.Player:getPlayerStats()
--     if not (plrStats and plrStats.Quests and plrStats.Quests.Active) then
--         warn("Invalid playerStats data")
--         return false, "Invalid playerStats data"
--     end

--     local activeQuests = plrStats.Quests.Active
--     local enabledNPCs = shared.main.Quest.enabledNPCs


--     for index, quest in pairs(activeQuests) do
--         local data = self:getQuestDataByName(quest.Name)
--         if data and data.Tasks and data.NPC and enabledNPCs[data.NPC] then
--             data.progress = self:getQuestProgress(data.Name, data.Tasks, plrStats)
--             actives[data.Name] = data
--         else
--             warn(data.Name,"NPC -> ".. data.NPC, enabledNPCs[data.NPC])
--         end
--     end


--     writefile('newActiveQuest.json', HttpService:JSONEncode(actives))
--     return actives
-- end

-- function QuestSystem:getQuestDataByName(questName)
--     local success, result = pcall(function()
--         for _, quest in ipairs(self.allQuests) do
--             if quest.Name == questName and quest.NPC then
--                 return quest
--             end
--         end
--     end)
--     if not success then
--         warn("Failed to get quest data by name:", questName, result)
--         return nil
--     end
--     return result
-- end
-- function QuestSystem:getQuestProgress(questName, questTask, plrStats)
--     local playerStats = plrStats
--     -- local success, result = pcall(function()
--         local activeQuestData = self.QuestService:Progress(questName, playerStats)
--         print(activeQuestData)
--         print(HttpService:JSONEncode(activeQuestData))

--     --     if not activeQuestData then
--     --         error("Line 6: activeQuestData is nil")
--     --     end

--     --     if type(questTask) ~= "table" then
--     --         error("Line 10: questTask is not a table (or nil)")
--     --     end

--     --     if type(activeQuestData.StartValues) ~= "table" then
--     --         error("Line 14: StartValues is not a table (or nil)")
--     --     end

--     --     return self.QuestService:GetProgression(
--     --         questTask,
--     --         playerStats,
--     --         activeQuestData.StartValues,
--     --         questName
--     --     )
--     -- end)

--     -- if not success then
--     --     warn("Failed to get quest progress for:", questName, result)
--     --     return nil
--     -- end

--     -- return result
-- end


-- return QuestSystem
