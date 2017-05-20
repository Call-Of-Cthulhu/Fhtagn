
-- 奖励骰与惩罚骰（Bonus Dice and Penalty Dice）
-- 传入正参数 count 的是奖励骰，反之则为惩罚骰
local BPDice = Class(function(self, count)
    self.count = count
end)

-- 把百分骰<投骰结果>拆为个位和十位
local function deduce(dice)
    assert(type(dice) == "number", "Invalid argument type!")
    return dice // 10, dice % 10
end

local function roll(count, d10, d00)
    if count > 0 then
        for i = 1, count do
            local res = Dice(1, 10)
            if res < d10 then
                d10 = res
            end
        end
    elseif count < 0 then
        for i = -1, count, -1 do
            local res = Dice(1, 10)
            if res > d10 then
                d10 = res
            end
        end
    end
    return d10 * 10 + d00
end

function BPDice:roll(dice)
    if type(dice) == "string" then
        dice = Dice(dice)
    end
    return roll(self.count, deduce(dice))
end

function BPDice.sum(...)
    local sum = 0
    for _, bpdice in ipairs{...} do
        sum = sum + bpdice.count
    end
    if sum == 0 then
        return nil
    end
    return BPDice(sum)
end

-- 工厂函数
return function(count)
    if count == nil or count == 0 then return nil end
    assert(type(count) == "number", "Invalid argument type!")
    return BPDice(count)
end
