-- 将投骰指令中的 DB 替换为数字
local function convert(player, dice)
    local attr = player.components.attribute
    local db = attr:GetDamageBonus()
    dice = string.gsub(dice, "[dD][bB]", tostring(db))
    -- TODO 替换技能点数、属性点数
    return dice
end

-- 请求投骰
-- 参数：
-- * action:        技能 ID 或属性 ID
--                      例如 SPOT_HIDDEN, SWIM, OPR_HVY_MCH,
--                      例如 STR, DEX, EDU, LUCK
-- * target:        作用对象，例如一个 NPC 或者一个环境物体
-- * player:        投骰主体 可选，默认调查员自己。
-- * difficulty:    对抗难度 可选，默认普通难度 TUNNING.DIFFICULTY.NORMAL
-- * dice:          骰子指令 可选，默认 1d100
DiceRequest = Class(function(self, action, target, player, difficulty, dice)
    if action == nil or player == nil then
        error("Invalid argument!")
    end
    self.action = action
    self.target = target
    self.player = player or ThePlayer
    self.difficulty = difficulty or TUNNING.DIFFICULTY.NORMAL
    self.dice = dice and convert(self.player, dice) or "1d100"

    -- TODO implement SetActiveDiceRequest, GetActiveDiceRequest
    self.player:SetActiveDiceRequest(self)
end)

-- 设置回调函数，大成功
function DiceRequest:SetOnCritical(fn)
    self.oncritical = fn
end

-- 设置回调函数，极难成功
function DiceRequest:SetOnExtreme(fn)
    self.onextreme = fn
end

-- 设置回调函数，困难成功
function DiceRequest:SetOnHard(fn)
    self.onhard = fn
end

-- 设置回调函数，普通成功
function DiceRequest:SetOnSuccess(fn)
    self.onsuccess = fn
end

-- 设置回调函数，失败
function DiceRequest:SetOnFailure(fn)
    self.onfailure = fn
end

-- 设置回调函数，大失败
function DiceRequest:SetOnFumble(fn)
    self.onfumble = fn
end

-- 服务器执行客户端的投骰请求
function DiceRequest:Execute()
    local result = DiceResult(self)
    -- TODO Push result back to client
    self:Push(result)
end

-- 客户端发送投骰请求到服务器
function DiceRequest:Send()
    -- TODO Remote Procedure Call
    return false
end

-- 服务器发送投骰结果到客户端
function DiceRequest:Push(result)
    -- TODO reverse-RPC
    -- assign 'request.result'
end

function DiceRequest:GetResult()
    return self.result
end
