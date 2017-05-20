-- 让一队调查员（doers）全部参与投骰（dice）
-- 对一个对象（target）发起行动（action）
-- 技能对抗难度为（difficulty）
-- 参数：
-- * doers:         检定主体列表，例如在站在一扇门附近的一行调查员
-- * action:        属性/技能 ID
-- * target:        作用对象
-- * difficulty:    对抗难度 可选，默认普通难度 TUNNING.DIFFICULTY.NORMAL
-- * dice:          骰子指令 可选，默认 1D100
DiceSession = Class(function(self, doers, action, target, difficulty, dice)
    self.doers = doers
    self.action = action
    self.target = target
    self.difficulty = difficulty
    self.dice = dice
end)

function DiceSession:RequestDice()
    for _, player in ipairs(self.doers) do
        local request = DiceRequest(self.action, self.target, self.difficulty, player, self.dice)
        -- TODO implement SetSession, GetSession
        player:SetSession(self)
        -- 发送请求
        local status = request:Send()
        -- 检查网络异常
        if not status then
            error("Lua> Net exception!")
        end
    end
end

function DiceSession:HasSuccess()
    for _, doer in ipairs(self.doers) do
        local req = doer:GetActiveRequest()
        if req.result then
            return true
        end
    end
end

function DiceSession:HasFailure()
    for _, doer in ipairs(self.doers) do
        local req = doer:GetActiveRequest()
        if not req.result then
            return true
        end
    end
end
