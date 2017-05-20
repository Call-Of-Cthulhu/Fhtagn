local BPDice = require("bpdice")

-- 降序比较函数
local function comp(p1, p2)
    p1 = p1.components.attribute
    p2 = p2.components.attribute
    local d1 = p1:GetCombatDEX()
    local d2 = p2:GetCombatDEX()
    -- TODO 两者敏捷持平时
    -- 拥有较高战斗技能（Combat Skill）的角色先行动
    -- TODO 宣称枪械的 +50
    return d1 > d2
end
--------------------------------------------------------------
--{伤害
local DamageDealer = {}
--(由 p1 对 p2 造成伤害
function DamageDealer.dealdamage(p1, p2)
    -- 获取攻击者的当前活跃投骰请求
    local req = p1:GetActiveDiceRequest()
    -- 获取攻击者的当前投骰请求的结果
    local res = req:GetResult()
    -- 获取攻击者的当前武器
    local wep = p1:GetActiveWeapon()
    -- * 如果攻击者攻击检定落入“极限成功”等级，他可以造成更大的伤害
    -- * 如果造成极限伤害的攻击是由非穿刺武器（Non-impaling Weapon）
    --      （大多数钝击武器，比如拳脚、棍棒，等等）
    --      进行的，它们会击中在敌人的要害部位，
    --      造成伤害骰可能的最大伤害（如果有伤害加权的话，
    --      也同样造成最大伤害）。
    -- * 如果造成极限伤害的攻击是由穿刺武器（Penetrating Weapon）
    --      （锐器、枪弹等）造成的，
    --      锋刃和弹头将穿透目标的身体，对脆弱的器官造成损伤，
    --      或撕裂关键的肌肉组织。
    --      ...
    --      除了按非穿刺武器的极限伤害规则
    --      （所有伤害骰和伤害加权取满）外，
    --      额外为武器再做一次伤害检定。
    if res:IsSuccess(TUNNING.DICERESULTS.EXTREME_SUCCESS) then
        -- 获取攻击者最大伤害加权
        local maxdb = p1.components.attribute:GetMaxDamageBonus()
        local wepdmg, base, maxdmg
        if wep then
            -- 获取武器原始伤害骰
            wepdmg = wep.dmg
            -- 去掉伤害加权的，武器的，基础伤害骰
            base = string.gsub(wepdmg, "+[Dd][Bb]", "")
        else
            -- 徒手格斗
            wepdmg = TUNNING.COMBAT.DEFAULT_DAMAGE.."+db"
            base = TUNNING.COMBAT.DEFAULT_DAMAGE
        end
        -- 伤害骰和伤害加权取满
        maxdmg = string.gsub(wepdmg, "%d*+[Dd](%d+)", "%1")
        maxdmg = string.gsub(maxdmg, "[Dd][Bb]", tostring(maxdb))
        maxdmg = eval("return "..maxdmg)
        -- 判断是不是穿刺武器
        -- TODO implement Weapon:CanImpale
        local imp = wep and wep:CanImpale()
        -- 计算结果
        return maxdmg + (imp and Dice(base) or 0)
    end
end --)
--}
--{战技
local ManeuverHandler = {}
--(战技步骤1：对比体格
function ManeuverHandler.CompareBuild(p1, p2)
    -- 战技发动者的体格
    local b1 = p1.components.attribute:GetBuild()
    -- 战技承受者的体格
    local b2 = p2.components.attribute:GetBuild()
    -- 双方体格差
    local bd = b2 - b1
    -- 如果尝试发动战技的一方的体格比对方小至少3级
    if bd > 2 then
        -- 那么他无法对对手发动战技
        return false
    -- 如果尝试发动战技的一方的体格比对方小2级
    elseif bd > 1 then
        -- 那么他在这次战技检定上承受两个惩罚骰
        return true, BPDice(2)
    -- 如果尝试发动战技的一方的体格比对方小1级
    elseif bd > 0 then
        -- 那么他在这次战技检定上承受一个惩罚骰
        return true, BPDice(1)
    -- 如果尝试发动战技的一方的体格与对方相同或者更高
    else
        -- 战技检定不受到任何影响
        return true
    end
end
--)
--(战技步骤2：进行攻击检定
--  大多数战技使用格斗（斗殴），即 FIGHTING(BRAWL)，来发动
--  但另一些情况下也可能使用特定的战斗技能，
--  比如使用格斗（剑）技能来，挑掉对手的武器
--  具体情况由守密人来裁定
function ManeuverHandler.AttackCheck(p1, p2, action)
    local fn = CombatAction.lookup[MANEU][action]
    if fn ~= nil then
        fn(p1, p2)
    end
end
--)
--(
function ManeuverHandler.HandleSuccess(p1, p2)
    -- 1. <缴械>，或<抢夺>一件物品
    -- 2. 使<对手>在接下来的行动承受一个<惩罚骰>
    -- 3. 使<所有队友>在对他发动的检定上获得一个<奖励骰>
    -- 4. 从被压制的状况下<脱离>。
    --      被对方压制的角色可以选择在<自己的回合>进行一次战技检定，
    --      挣脱擒抱，锁喉以及类似的效果。
    --      如果他不主动挣脱，压制者可以选择一直保持控制他直到放手
    -- 5. 将对手撞落悬崖，或从窗户推出去，甚至是简单的绊倒在地
end
--)
--}

--{战斗动作
CombatAction = Class(function(self, atk, dfd, catg, desc)
    self.atk = atk
    self.dfd = dfd
    self.catg = catg
    self.desc = desc
end)
-- 先查找攻击方动作，后查找防御方动作
CombatAction.lookup = table.easytable()
--(
CombatAction.lookup[MELEE][MELEE] = function(p1, p2)
    -- 两者同时格斗技能检定
    local act1 = p1:GetActiveWeapon()
    local act2 = p2:GetActiveWeapon()
    local drq1 = DiceRequest(act1, p2, p1)
    local drq2 = DiceRequest(act2, p1, p2)
    local res1 = drq1:Get()
    local res2 = drq2:Get()
    -- 成功等级较高的那一方对另一方造成伤害，
    -- 并且自己不受到伤害
    -- （数值越小越成功）
    if drq1:IsFailure() and drq2:IsFailure() then
        -- * 攻守双方投骰均失败，无事发生（打王八拳）
        return
    elseif res1 <= res2 then
        -- * 攻击者获得较高成功等级，于是命中并伤害对手
        -- * 如果双方平手，则视为攻击者成功命中
        DamageDealer.dealdamage(p1, p2)
    elseif res1 > res2 then
        -- * 被攻击者获得较高成功等级
        --      于是不但成功闪避/格挡/招架了敌人的攻击
        --      同时反击林攻击者，命中并造成伤害
        DamageDealer.dealdamage(p2, p1)
    end
end
--)(
CombatAction.lookup[MELEE][DODGE] = function(p1, p2)
    local act1 = p1:GetActiveWeapon()
    local act2 = "DODGE"
    local drq1 = DiceRequest(act1, p2, p1)
    local drq2 = DiceRequest(act2, p1, p2)
    local res1 = drq1:Get()
    local res2 = drq2:Get()
    if drq1:IsFailure() and drq2:IsFailure() then
        -- * 攻守双方投骰均失败，无事发生
        return
    elseif res1 < res2 then
        -- * 攻击者获得较高成功等级，于是命中并伤害对手
        DamageDealer.dealdamage(p1, p2)
    elseif res1 >= res2 then
        -- * 被攻击者获得较高成功等级
        --      于是成功闪避了敌人的攻击
        -- * 如果双方平手，则视为被攻击者成功闪避
        return
    end
end
--)(
CombatAction.lookup[MANEU][DODGE] = function(p1, p2)
    local act1 = p1:GetActiveAction()
    local act2 = p2:GetActiveAction()
    local drq1 = DiceRequest(act1, p2, p1)
    local drq2 = DiceRequest(act2, p1, p2)
    local res1 = drq1:Get()
    local res2 = drq2:Get()
    if drq1:IsFailure() and drq2:IsFailure() then
        -- * 攻守双方投骰均失败，无事发生
        return
    elseif res1 < res2 then
        -- * 攻击者获得较高成功等级，于是发动战技成功
        ManeuverHandler.HandleSuccess(p1, p2)
    elseif res1 >= res2 then
        -- * 被攻击者获得较高成功等级
        --      于是成功闪避了敌人的攻击
        -- * 如果双方平手，则视为被攻击者成功闪避
        return
    end
end
--)(
CombatAction.lookup[MANEU][MELEE] = function(p1, p2)
    local act1 = p1:GetActiveAction()
    local act2 = p2:GetActiveAction()
    local drq1 = DiceRequest(act1, p2, p1)
    local drq2 = DiceRequest(act2, p1, p2)
    local res1 = drq1:Get()
    local res2 = drq2:Get()
    if drq1:IsFailure() and drq2:IsFailure() then
        -- * 攻守双方投骰均失败，无事发生
        return
    elseif res1 <= res2 then
        -- * 攻击者获得较高成功等级，于是发动战技成功
        -- * 如果双方平手，则视为攻击者发动战技成功
        ManeuverHandler.HandleSuccess(p1, p2)
    elseif res1 > res2 then
        -- * 被攻击者获得较高成功等级，则战技失败
        --      且被攻击者对攻击者造成伤害
        DamageDealer.dealdamage(p2, p1)
    end
end
--)(
CombatAction.lookup[MANEU][MANEU] = function(p1, p2)
    local act1 = p1:GetActiveAction()
    local act2 = p2:GetActiveAction()
    local drq1 = DiceRequest(act1, p2, p1)
    local drq2 = DiceRequest(act2, p1, p2)
    local res1 = drq1:Get()
    local res2 = drq2:Get()
    if drq1:IsFailure() and drq2:IsFailure() then
        -- * 攻守双方投骰均失败，无事发生
        -- * 如果双方平手，则视为攻击者发动战技成功
        return
    elseif res1 <= res2 then
        -- * 攻击者获得较高成功等级，于是发动战技成功
        ManeuverHandler.HandleSuccess(p1, p2)
    elseif res1 > res2 then
        -- * 被攻击者获得较高成功等级，则战技失败
        --      且被攻击者对攻击者发动战技成功
        ManeuverHandler.HandleSuccess(p2, p1)
    end
end
--)
--}

local Combat = Class(function(self)
    -- 战斗参与者 Participants
    self.part = {}
    -- 战斗事件表
    self.stat = {}
    -- 比较
    self.comp = comp
    -- TODO 突袭
    -- 允许技能检定
    -- 目标意识到攻击林名？（侦查、聆听、心理学）
    -- * 是：   使用正常 DEX 次序来战斗
    -- * 否：   攻击自动成功或有奖励骰
end)

function Combat:Join(inst)
    self.part[inst] = inst
end

function Combat:GetAvailableActions(player)
    local action = self.stat[player]
    local result
    if action == nil then
        result = TUNNING.COMBAT_ACTION.ALL
    else
        result = {}
        local entries = CombatAction.lookup[action]
        for k, func in pairs(entries) do
            table.insert(result, k)
        end
    end
    return result
end

--{回合/战斗轮 Combat Round
-- TODO “时间和空间？”
--          战斗者在空间和时间上的分布是怎么决定的？
function Combat:RunRound()
    local list = {}
    -- 把所有参与者添加到本轮战斗的数组中
    for k, _ in pairs(self.part) do table.insert(list, k) end
    -- 按照敏捷（DEX）降序，最高的先行动
    table.sort(list, self.comp)
    -- 依次通知列表中的角色
    for i, player in ipairs(list) do
        -- TODO implement
        local action = player:NotifyCombatRound(self)
        -- 根据动作对本轮战斗的战斗轮进行修改
        -- 例如延迟（delay）攻击
        handleaction(list, action)
    end
    -- 如果多个角色同时选择延迟到同一个时刻行动
    -- 那么他们的行动次序也由敏捷度降序排列
    --
    -- 如果所有的角色都向后延迟，则下一轮再按照正常次序开始自己的行动
end --}

local function IsVisibleTo(attackers, defenders)
    for i1, v1 in ipairs(attackers) do
        for i2, v2 in ipairs(defenders) do
            if v1:IsVisibleTo(v2) then
                return true
            end
        end
    end
end

--{创建战斗
-- 参数：
-- * atk:           进攻方列表
-- * dfd:           防御方列表
-- * surprise:      是否突袭，可以缺省，默认突袭
function InitiateCombat(atk, dfd, surprise)
    if surprise == nil then surprise = true end
    if surprise then
        if not TUNNING.COMBAT.DIRECT_FIGHT then
            -- 检定突袭是否被发现
            if not IsVisibleTo(atk, dfd) then
                -- 突袭方身体不可见时
                -- 被突袭方检定侦查、聆听
                for i, v in ipairs(atk) do
                    local skill = v.components.skill
                    -- TODO implement GetDifficulty
                    local d = skill:GetDifficulty("STEALTH")
                    if DiceSession(dfd, "SPOT_HIDDEN", v, d):HasSuccess()
                        or DiceSession(dfd, "LISTEN", v, d):HasSuccess()
                    then
                        surprise = false
                        break
                    end
                end
                -- 突袭方检定隐秘行动
                if surprise then
                    for i, v in ipairs(dfd) do
                        local skill = v.components.skill
                        local d1 = skill:GetDifficulty("SPOT_HIDDEN")
                        local d2 = skill:GetDifficulty("LISTEN")
                        if DiceSession(atk, "STEALTH", v, d1):HasFailure()
                            or DiceSession(atk, "STEALTH", v, d2):HasFailure()
                        then
                            surprise = false
                            break
                        end
                    end
                end
            else
                -- 突袭方身体可见时
                -- 被突袭方检定心理学
                for i, v in ipairs(atk) do
                    local skill = v.components.skill
                    local d = skill:GetDifficulty("STEALTH")
                    if DiceSession(dfd, "PSYCHOLOGY", v, d):HasSuccess() then
                        surprise = false
                        break
                    end
                end
                -- 突袭方检定隐秘行动
                if surprise then
                    for i, v in ipairs(dfd) do
                        local skill = v.components.skill
                        local d1 = skill:GetDifficulty("SPOT_HIDDEN")
                        local d2 = skill:GetDifficulty("LISTEN")
                        if DiceSession(atk, "STEALTH", v, d1):HasFailure()
                            or DiceSession(atk, "STEALTH", v, d2):HasFailure()
                        then
                            surprise = false
                            break
                        end
                    end
                end
            end
        end
    end
    -- 突袭未被发现，结算突袭伤害
    if surprise then
        -- TODO
    -- 突袭被发现了，被突袭方选择对这次攻击进行<闪避>或者<反击>
    else
        -- TODO
    end
end --}



