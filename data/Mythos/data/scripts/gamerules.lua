TUNNING = table.easytable()

-- 默认最大自动生成属性次数
TUNNING.DEFAULT_ATTRIBUTE_GENERATION_LIMIT = 3
-- 默认不开启 PVP
TUNNING.IS_PVP_ENABLED = false
-- 定义现代
TUNNING.DEFINITION.PRESENT = "PRESENT"
------------------------------------------------------
-- 常数 枚举值 Dice Result Enum
TUNNING.DICERESULTS =
{
    -- 大成功
    CRITICAL_SUCCESS = 1,
    -- 极难成功
    EXTREME_SUCCESS = 2,
    -- 困难成功
    HARD_SUCCESS = 3,
    -- 普通成功
    REGULAR_SUCCESS = 4,
    -- 失败
    FAILURE = 5,
    -- 大失败
    FUMBLE = 6,
}
TUNNING.CANALTERDICERESULT = false
TUNNING.DIFFICULTY =
{
    NORMAL  = 1,
    HARD    = 2,
    EXTREME = 3,
}
------------------------------------------------------

--{战斗 Combat
-- 突袭情形
-- DIRECT_FIGHT 为 true 时，突袭者结算伤害后直接进入战斗轮
-- DIRECT_FIGHT 为 false 时，突袭者必须检定其行动是否被对方发现
TUNNING.COMBAT.DIRECT_FIGHT = false
-- STRICT_SURPRISE 为 true 时，突袭行动严格按照规则书进行检定（恶意）
-- STRICT_SURPRISE 为 false 时，突袭行动按照“技能对抗”进行检定
TUNNING.COMBAT.STRICT_SURPRISE = true
-- 在没有任何武装的情况下，人类徒手格斗伤害骰为
TUNNING.COMBAT.DEFAULT_DAMAGE = "1d3"
-- 战斗动作类别
TUNNING.COMBAT_ACTION.CATEGORY =
{
    -- 延迟攻击
    DELAY           = 0,
    -- 近战
    MELEE           = 1,
    -- 远程攻击
    RANGE           = 2,
    -- 闪避
    DODGE           = 3,
    -- 战技 Fighting Maneuvers
    MANEU           = 6,
    -- 脱离战斗并逃跑 Flee
    FLEE            = 7,
    -- 施展咒文
    SPELL           = 8,
    -- 其他需要时间和检定投骰的动作
    OTHER           = 9
}
TUNNING.COMBAT_ACTION.ALL = {}
for k, _ in pairs(TUNNING.COMBAT_ACTION.CATEGORY) do
    table.insert(TUNNING.COMBAT_ACTION.ALL, k)
end
------------------------------------------------

--}

