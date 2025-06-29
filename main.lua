shared.Helpers = {}
shared.isGithub = true
if shared.isGithub then
    shared.URL = "https://raw.githubusercontent.com/SixZacScript/NewBee3/master"
    shared.ModuleLoader = loadstring(game:HttpGet(shared.URL..'/Helper/Module.lua'))()
else
    shared.URL = "NewBee3"
    shared.ModuleLoader = loadstring(readfile(shared.URL..'/Helper/Module.lua'))()
end
if not shared.isGithub then
    loadstring(game:HttpGet('https://raw.githubusercontent.com/DarkNetworks/Infinite-Yield/main/latest.lua'))()
end
shared.main = shared.ModuleLoader:load('Data/State.lua')
shared.Data = {
    TokenData = shared.ModuleLoader:load('Data/Token.lua')
}
shared.Helpers = shared.ModuleLoader:loadAllHelpers()
local FluentModule = shared.ModuleLoader:load('UI/UI.lua')
-- local QuestModule = shared.ModuleLoader:load('Class/Quest.lua')
local BotModule = shared.ModuleLoader:load('Class/Bot.lua')


shared.Bot = BotModule.new()
-- shared.Quest = QuestModule.new()
shared.FluentUI = FluentModule.new()
