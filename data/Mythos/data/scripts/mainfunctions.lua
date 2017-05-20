function CreateEntity()
    --print("Creating "..tostring(NumEnts + 1).."-th entity ...")
    local ent = TheSim:CreateEntity()
    --print("TheSim:CreateEntity [done]")
    local uuid = ent:GetUUID()
    --print("ent:GetUUID [done]")
    local scr = EntityScript(ent)
    --print("Entity:", scr)
    Ents[uuid] = scr
    NumEnts = NumEnts + 1
    return scr
end

function PopupAgePenalty(adjust, entries)
    -- TODO
    --for k, v in pairs(entries) do
    --end
end

--[[
function GenerateRandomTraits()
    local belief = STRINGS.BELIEFS[Dice(1, 10)]
    belief = belief[Dice(1, #belief)]
    print("意识形态:", belief)
    local vip = STRINGS.IMPORTANT_PERSON[Dice(1, 10)]
    vip = vip[Dice(1, #vip)]
    print("重要之人:", vip)
end

function SpawnPrefab(name, creator)
    local id = TheSim:SpawnPrefab(name, creator)
    return Ents[id]
end
--]]
