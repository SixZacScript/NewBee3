local TokenHelper = {}
TokenHelper.tokens = {
    ["Diamond Egg"] = {id = 1471850677, isSkill = false, Priority = 100, isRare = true},
    ["Star Jelly"] = {id = 2319943273, isSkill = false, Priority = 100, isRare = true},
    ["Gold Egg"] = {id = 1471849394, isSkill = false, Priority = 95, isRare = true},
    ["Sprout"] = {id = 2529092020, isSkill = false, Priority = 90, isRare = true},
    ["Hard Wax"] = {id = 8277780065, isSkill = false, Priority = 90, isRare = true},

    ["Moon Charm"] = {id = 2306224708, isSkill = false, Priority = 89, isRare = true},
    ["Oil"] = {id = 2545746569, isSkill = false, Priority = 89, isRare = true},
    ["Glitter"] = {id = 2542899798, isSkill = false, Priority = 89, isRare = true},
    ["Glue"] = {id = 2504978518, isSkill = false, Priority = 89, isRare = true},
    ["Loaded Dice"] = {id = 8055428094, isSkill = false, Priority = 89, isRare = true},
    ["Ticket"] = {id = 1674871631, isSkill = false, Priority = 85, isRare = true},
    ["Neon Berry"] = {id = 4483267595, isSkill = false, Priority = 85, isRare = true},
    ["Blue Extract"] = {id = 2495936060, isSkill = false, Priority = 80, isRare = true},
    ["Red Extract"] = {id = 2495935291, isSkill = false, Priority = 80, isRare = true},
    ["Dice"] = {id = 2863468407, isSkill = false, Priority = 80, isRare = true},
    ["Soft Wax"] = {id = 8277778300, isSkill = false, Priority = 80, isRare = true},
    ["Star"] = {id = 2000457501, isSkill = true, Priority = 80},
    ["Stinger"] = {id = 2314214749, isSkill = false, Priority = 80},
    ["Silver Egg"] = {id = 1471848094, isSkill = false, Priority = 80, isRare = true},

    ["Link Token"] = {id = 1629547638, isSkill = true, Priority = 75},
    ["Baby Love"] = {id = 1472256444, isSkill = true, Priority = 74},
    ["Tabby Love"] = {id = 1753904617, isSkill = true, Priority = 74},
    ["Buzz Bomb Plus"] = {id = 1442764904, isSkill = true, Priority = 70},
    ["Blue Sync"] = {id = 1874692303, isSkill = true, Priority = 70},
    ["Red Sync"] = {id = 1874704640, isSkill = true, Priority = 70},
    ["Scratch"] = {id = 1104415222, isSkill = true, Priority = 70},
    ["Melody"] = {id = 253828517, isSkill = true, Priority = 70},

    ["Red Boost"] = {id = 1442859163, isSkill = true, Priority = 65, isRare = true},
    ["Blue Boost"] = {id = 1442863423, isSkill = true, Priority = 65, isRare = true},
    ["White Boost"] = {id = 3877732821, isSkill = true, Priority = 65},
    ["Dice 2"] = {id = 8054996680, isSkill = false, Priority = 65},
    ["Buzz Bomb"] = {id = 1442725244, isSkill = true, Priority = 64},
    ["Pulse"] = {id = 1874564120, isSkill = true, Priority = 63},
    ["Focus"] = {id = 1629649299, isSkill = true, Priority = 60},
    ["Bitter Berry"] = {id = 4483236276, isSkill = false, Priority = 60},

    ["bbm1"] = {id = 2652364563, isSkill = true, Priority = 55},
    ["Bee Bear Token"] = {id = 2652424740, isSkill = true, Priority = 55},
    ["Pollen Mark"] = {id = 2499540966, isSkill = true, Priority = 55},
    ["Honey Mark"] = {id = 2499514197, isSkill = true, Priority = 55},
    ["Honey Suckle"] = {id = 8277901755, isSkill = false, Priority = 50},
    ["Ant Pass"] = {id = 2060626811, isSkill = false, Priority = 50},
    ["Broken Drive"] = {id = 13369738621, isSkill = false, Priority = 50},

    ["Cloud Vial"] = {id = 3030569073, isSkill = false, Priority = 45, isRare = true},
    ["Micro Converter"] = {id = 2863122826, isSkill = false, Priority = 45, isRare = true},
    ["Robot Pass"] = {id = 3036899811, isSkill = false, Priority = 40},
    ["Gumdrops"] = {id = 1838129169, isSkill = false, Priority = 40},
    

    ["Pineapple Candy"] = {id = 2584584968, isSkill = false, Priority = 35},
    ["Red Balloon"] = {id = 8058047989, isSkill = false, Priority = 30},
    ["Jelly Bean 1"] = {id = 3080529618, isSkill = false, Priority = 30},
    ["Jelly Bean 2"] = {id = 3080740120, isSkill = false, Priority = 30},
    ["Whirligig"] = {id = 8277898895, isSkill = false, Priority = 30},

    ["Coconut"] = {id = 3012679515, isSkill = false, Priority = 25, isRare = true},
    ["Blueberry"] = {id = 2028453802, isSkill = false, Priority = 25, isRare = true},
    ["Sunflower Seed"] = {id = 1952682401, isSkill = false, Priority = 25, isRare = true},
    ["Pineapple"] = {id = 1952796032, isSkill = false, Priority = 25, isRare = true},
    ["Strawberry"] = {id = 1952740625, isSkill = false, Priority = 25, isRare = true},
    ["Royal Jelly"] = {id = 1471882621, isSkill = false, Priority = 20},

    ["Rage"] = {id = 1442700745, isSkill = true, Priority = 1},
    ["Haste"] = {id = 65867881, isSkill = true, Priority = 1},
    ["Treat"] = {id = 2028574353, isSkill = false, Priority = 1},
    ["Honey"] = {id = 1472135114, isSkill = false, Priority = 1},
}


function TokenHelper:getPriorityById(searchId)
    for _, data in pairs(self.tokens) do
        if data.id == searchId then
            return data.Priority
        end
    end
    return 1
end

function TokenHelper:getTokenById(searchId)
    for name, data in pairs(self.tokens) do
        if data.id == searchId then
            data['Name'] = name
            return name, data
        end
    end

    if not self.unknownTokenIds then
        self.unknownTokenIds = {}
    end

    if not table.find(self.unknownTokenIds, searchId) then
        table.insert(self.unknownTokenIds, searchId)

        local HttpService = game:GetService("HttpService")
        local filename = "UnknownTokens.json"
        local content = ""

        if isfile(filename) then
            local oldData = HttpService:JSONDecode(readfile(filename))
            for _, v in ipairs(oldData) do
                if not table.find(self.unknownTokenIds, v) then
                    table.insert(self.unknownTokenIds, v)
                end
            end
        end

        content = HttpService:JSONEncode(self.unknownTokenIds)
        writefile(filename, content)
    end

    return "Unknown", { id = searchId, isSkill = false, Priority = 1, Name = "Unknown" }
end

function TokenHelper:getRareToken(getOnlyName)
    local tokens = {}
    for key, token in pairs(self.tokens) do
        if token.isRare and getOnlyName then
            table.insert(tokens, key)
        elseif token.isRare and not getOnlyName then
            table.insert(tokens, token)
        end
    end

    table.sort(tokens, function(a, b)
        return (getOnlyName and a or a.Name) < (getOnlyName and b or b.Name)
    end)

    return tokens
end

function TokenHelper:getTokenByName(name)
    local data = self.tokens[name]
    if data then
        data.Name = name
        return data
    end
    return nil
end



return TokenHelper
