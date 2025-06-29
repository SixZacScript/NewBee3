local ModuleLoader = {}

ModuleLoader.helperFiles = {
    "Helper/Field.lua",
    "Helper/Player.lua",
    "Helper/Hive.lua",
    "Helper/Token.lua",
    "Helper/Hide.lua",
    "Helper/Gui.lua",
    "Helper/Npc.lua",
}

function ModuleLoader:load(path)
    assert(shared.URL, "shared.URL is nil")
    local base = shared.URL .. "/" .. path

    local success, result = pcall(function()
        local source = shared.isGithub and game:HttpGet(base) or readfile(base)
        return loadstring(source)()
    end)

    if not success then
        warn("[ModuleLoader] Failed to load module:", path, "\nError:", result)
        return nil
    end

    return result
end

function ModuleLoader:loadAllHelpers()
    local loadedHelpers = {}
    for _, filePath in ipairs(self.helperFiles) do
        local module = self:load(filePath)
        local key = filePath:match("([^/]+)%.lua$")

        if module then
            if type(module) == "table" and type(module.new) == "function" then
                loadedHelpers[key] = module.new()
            else
                loadedHelpers[key] = module
            end
        else
            warn("[ModuleLoader] Skipped loading:", key)
        end
    end

    return loadedHelpers
end

return ModuleLoader
