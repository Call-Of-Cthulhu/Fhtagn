local BPDice = require("bpdice")

Keeper = Class(function(self)
    self.inst = TheSim:CreateEntity()
end)

function Keeper:GetAttributeTable(inst)
    return inst.components.attribute
end

function Keeper:CreateDiceRequest(inst, action)
    return DiceRequest(action, nil, inst)
end

function Keeper:CreateDiceSession(list, action)
end

function Keeper:HandleDiceRequest(dice_request)
end

function Keeper:HandleDiceSession(dice_session)
end

function Keeper:HandleInventory(inst)
end

function Keeper:Kill(inst)
end

function Keeper:Revive(inst)
end

function Keeper:Remove(inst)
end


