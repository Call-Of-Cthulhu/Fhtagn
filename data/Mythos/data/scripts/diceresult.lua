-- 投骰结果
DiceResult = Class(function(self, request)
    self.action = string.upper(request.action)
    self.target = request.target
    self.difficulty = request.difficulty
    self.player = request.player
    self.dice = Dice(request.dice)

    self.request = request
end)

--{
--玩家通过花费幸运值更改投骰结果
--参数：
--* delta:      花费的幸运值
--返回值：      当幸运值足够时返回 true，否则返回 false
function DiceResult:Alter(delta)
    -- 首先确认规则是否可选 CanAlterDiceResult
    if not TUNNING.CANALTERDICERESULT then return end
    local attr = player.components.attribute
    local luck = attr.luck
    if luck > delta then
        luck = luck - delta
        self.dice = self.dice - delta
        if self.dice < 1 then self.dice = 1 end
        return true
    else
        return false
    end
    -- TODO RPC 从客户端发送请求
end
--}{
-- 获取投骰结果
function DiceResult:Get()
    local request = self.request
    local atp = player.components.attribute
    local skp = player.components.skill
    local criteria = nil
    local isr
    -- 属性骰
    if #self.action == 3 or self.action == "LUCK" then
        criteria = atp[string.lower(self.action)]
        isr = false
    end
    -- 技能骰
    if not criteria then
        criteria = skp[self.action]
        isr = true
    end
    if not criteria then
        error("Invalid roll ("..tostring(self.action)..")!")
    end
    local result
    --(
    -- 大成功
    if self.dice == 1 then
        if request.oncritical then
            request.oncritical(self.player, self.target)
        end
        result = TUNNING.DICERESULTS.CRITICAL_SUCCESS
    end
    -- 大失败
    if self.dice == 100 or criteria < 50 and self.dice > 95 then
        if request.onfumble then
            request.onfumble(self.player, self.target)
        end
        result = TUNNING.DICERESULTS.FUMBLE
    -- 失败
    elseif self.dice > criteria then
        if request.onfailure then
            request.onfailure(self.player, self.target)
        end
        result = TUNNING.DICERESULTS.FAILURE
    -- 普通成功
    elseif self.dice > criteria // 2 then
        if request.onsuccess then
            request.onsuccess(self.player, self.target)
        end
        result = TUNNING.DICERESULTS.REGULAR_SUCCESS
    -- 困难成功
    elseif self.dice > criteria // 5 then
        if request.onhard then
            request.onhard(self.player, self.target)
        end
        result = TUNNING.DICERESULTS.HARD_SUCCESS
    -- 极难成功
    else
        if request.onextreme then
            request.onextreme(self.player, self.target)
        end
        result = TUNNING.DICERESULTS.EXTREME_SUCCESS
    end
    --)
    return result
end
--}{
-- 技能对抗
-- 根据技能作用对象的技能点数决定对抗难度
-- 参数：
-- * expect:        期望的成功等级
-- 返回：
function DiceResult:IsSuccess(expect)
    return expect == nil
        and not self:IsFailure()
        or  self:Get() <= expect
end
function DiceResult:IsFailure()
    return self:Get() > self.difficulty
end
--}
