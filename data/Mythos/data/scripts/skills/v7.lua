if COC_VERSION ~= 7 then return end
-- KaiserKatze:
-- 在本项目中，魅惑（CHARM）、话术（FAST_TALK）、恐吓（INTIMIDATE）和劝说（PERSUADE）四个技能
-- 将作为一个原本7版规则中并不存在的技能 社交（SOCIAL）的子技能
Skill("SOCIAL"):SetOppoSkills("PSYCHOLOGY")

-- 会计
Skill("ACCOUNTING", 5)
-- 表演 @Art/Craft
Major("ART", "ACTING", 5)
-- 动物驯养 hidden
Skill("ANIMAL_HANDLING", 5):SetHidden(true)
-- 人类学
Skill("ANTHROPOLOGY", 1)
-- 估价 5
Skill("APPRAISE", 5)
-- 考古学
Skill("ARCHAEOLOGY", 1)
-- 艺术和工艺*
Skill("ART", 5):SetSpec(true)
-- 炮术 hidden
Skill("ARTILLERY", 1):SetCombatSkill(true):SetHidden(true)
-- 天文学 @Science
Major("SCIENCE", "ASTRONOMY", 1)
-- 斧头 @Fighting
Major("FIGHTING", "AXE", 15)
-- 生物学 @Science
Major("SCIENCE", "BIOLOGY", 1)
-- 植物学 @Science
Major("SCIENCE", "BOTANY", 1)
-- 弓术 @Firearms
Major("FIREARMS", "BOW", 15)
-- 斗殴 25 @Fighting
Major("FIGHTING", "BRAWL", 25)
-- 电锯 10 @Fighting
Major("FIGHTING", "CHAINSAW", 10)
-- 魅惑 15
Major("SOCIAL", "CHARM", 15)
-- 化学 @Science
Major("SCIENCE", "CHEMISTRY", 1)
-- 攀爬
Skill("CLIMB", 20)
-- 电脑使用 5 #现代
Skill("COMPUTOR_USE", 5, 2000)
-- 信誉等级
Skill("CREDIT_RATING", 0)
-- 密码学 1 @Science
Major("SCIENCE", "CRYPTOGRAPHY", 1)
-- 克苏鲁神话
Skill("CTHULHU_MYTHOS", 0)
-- 爆破 1 hidden
Skill("DEMOLITIONS", 1):SetHidden(true)
-- 乔装
Skill("DISGUISE", 5):SetOppoSkills("PSYCHOLOGY")
-- 潜水
Skill("DIVING", 1):SetHidden(true)
-- 闪避
Skill("DODGE", function(inst) return inst.components.attribute.dex // 2 end):SetCombatSkill(true)
-- 汽车驾驶
Skill("DRIVE_AUTO", 20, 1920)
-- 电气维修
Skill("ELECTR_REPAIR", 10)
-- 电子学 #现代
Skill("ELECTRONICS", 1, 2000)
-- 工程学
Major("SCIENCE", "ENGINEERING", 1)
-- 话术
Major("SOCIAL", "FAST_TALK", 5)
-- 格斗* Fighting
Skill("FIGHTING"):SetCombatSkill(true):SetSpec(true)
-- 美术 5 @Art/Craft
Major("ART", "FINE_ART", 5)
-- 射击* Firearms
Skill("FIREARMS"):SetCombatSkill(true):SetSpec(true)
-- 急救
Skill("FIRST_AID", 30)
-- 连枷 10 @Fighting
Major("FIGHTING", "FLAIL", 10)
-- 火焰喷射器 10 @Firearms
Major("FIREARMS", "FLAMETHROWER", 10)
-- 法医学 1 @Science (物证学)
Major("SCIENCE", "FORENSICS", 1)
-- 伪造 5 @Art/Craft
Major("ART", "FORGERY", 5)
-- 绞杀 15 @Fighting
Major("FIGHTING", "GARROTE", 15)
-- 地质学 @Science
Major("SCIENCE", "GEOLOGY", 1)
-- 手枪 @Firearms
Major("FIREARMS", "HANDGUN", 20)
-- 重武器 10 @Firearms
Major("FIREARMS", "HVY_WEAPONS", 10)
-- 历史
Skill("HISTORY", 5)
-- 催眠 1 hidden
Skill("HYPNOSIS", 1):SetHidden(true)
-- 恐吓 15
Major("SOCIAL", "INTIMIDATE", 15)
-- 跳跃
Skill("JUMP", 20)
-- 语言（其他） *
Skill("OTHER_LANGUAGE", 1):SetSpec(true)
-- 语言（母语）
Skill("OWN_LANGUAGE", function(inst) return inst.components.attribute.edu:get() end)
-- 法律
Skill("LAW", 5)
-- 图书馆使用
Skill("LIBRARY_USE", 20)
-- 聆听
Skill("LISTEN", 20):SetOppoSkills("STEALTH")
-- 锁匠
Skill("LOCKSMITH", 1)
-- 机关枪 @Firearms
Major("FIREARMS", "MACHINE_GUN", 10)
-- 数学 1 @Science
Major("SCIENCE", "MATH", 1)
-- 机械维修
Skill("MECH_REPAIR", 10)
-- 医学
Skill("MEDICINE", 1)
-- 气象学 1 @Science
Major("SCIENCE", "METEOROLOGY", 1)
-- 自然学 10
Skill("NATURAL_WORLD", 10)
-- 领航
Skill("NAVIGATE", 10)
-- 神秘学
Skill("OCCULT", 5)
-- 操作重型机械
Skill("OPR_HVY_MCH", 1)
-- 说服
Major("SOCIAL", "PERSUADE", 10)
-- 药学 @Science
Major("SCIENCE", "PHARMACY", 1)
-- 摄影 @Art/Craft
Major("ART", "PHOTOGRAPHY", 5)
-- 物理 @Science
Major("SCIENCE", "PHYSICS", 1)
-- 驾驶*
Skill("PILOT", 1, 1920):SetSpec(true)
-- 驾驶（飞行器） —— 通常来说，每种飞行器都有各自独立的技能
Major("PILOT", "AIRCRAFT"):SetCanUse(false)
-- 驾驶（船）
Major("PILOT", "BOAT")
-- 精神分析
Skill("PSYCHOANALYSIS", 1):SetOnSuccess(function(p1, p2)
    p2.components.sanity:DoDelta("1d3")
end):SetOnFumble(function(p1, p2)
    p2.components.sanity:DoDelta("-1d6")
end)
-- 心理学
Skill("PSYCHOLOGY", 10):SetOppoSkills("SOCIAL","DISGUISE","STEALTH")
-- 读唇术 1 hidden
Skill("READ_LIPS", 1):SetHidden(true):SetOppoSkills("STEALTH")
-- 骑术
Skill("RIDE", 5)
-- 步枪/霰弹枪 @Firearms(Rifle/Shotgun)
Major("FIREARMS", "RIFLE_SHOTGUN", 25)
-- 科学*
Skill("SCIENCE", 1):SetSpec(true)
-- 手上功夫 10
Skill("SLEIGHT_OF_HAND", 10):SetOppoSkills("SPOT_HIDDEN")
-- 矛 20 @Fighting
Major("FIGHTING", "SPEAR", 20)
-- 侦查
Skill("SPOT_HIDDEN", 25):SetOppoSkills("STEALTH", "SLEIGHT_OF_HAND")
-- 隐秘行动
Skill("STEALTH", 20):SetOppoSkills("SPOT_HIDDEN","LISTEN","PSYCHOLOGY","READ_LIPS","TRACK")
-- 冲锋枪 @Firearms
Major("FIREARMS", "SMG", 15, 1920)
-- 生存 10 *
Skill("SURVIVAL", 10):SetSpec(true)
-- 一般是根据环境确定
Major("SURVIVAL", "DESERT")
Major("SURVIVAL", "OCEAN")
Major("SURVIVAL", "ARCTIC")
Major("SURVIVAL", "JUNGLE")
-- 剑 20 @Fighting
Major("FIGHTING", "SWORD", 20)
-- 游泳
Skill("SWIM", 20)
-- 投掷 20
Skill("THROW", 25)
-- 追踪 10
Skill("TRACK", 10):SetOppoSkills("STEALTH")
-- 鞭子 5 @Fighting
Major("FIGHTING", "WHIP", 5)
-- 动物学 1 @Science
Major("SCIENCE", "ZOOLOGY", 1)
