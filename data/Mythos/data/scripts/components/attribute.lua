
--{
-- 教育增强检定
local function DoEducate(self, count)
    local edu = self.edu
    local fix = edu.fix
    local src = #fix + 1
    if src >= count then
        return false
    end
    for i = src, count do
        local dice = Dice("1d100")
        if dice > edu then
            local delta = Dice("1d10")
            fix[i] = delta
        end
    end
    return true
end
-- 衰老 属性惩罚
local function DoAge(self, adjust, dapp)
    PopupAgePenalty(adjust, {
        STR = self.str,
        CON = self.con,
        DEX = self.dex
    })
    self.app:delta(dapp)
end
local OnAgeChanged = function(self, doeducate)
    local age = self.age
    self.str:dup()
    self.con:dup()
    self.siz:dup()
    self.dex:dup()
    self.app:dup()
    self.int:dup()
    self.pow:dup()
    self.edu:dup()
    if      age < 20 then
        self.str:delta(-5)
        self.siz:delta(-5)
        self.edu:delta(-5)
        self.luck = math.max(table.unpack(self.luck))
    elseif  age < 40 then
        if doeducate then
            DoEducate(self, 1)
        end
    else
        local delta = age - 30
        local level = delta // 10
        DoAge(self, 5 * 2 ^ (level - 1), 5 * level)
        if doeducate then
            if level > 4 then level = 4 end
            DoEducate(self, level)
        end
    end
end
--}

--[[
 * When hit points reach 2 or less, characters go unconscious,
    and no longer influence the game.
 * When hit points reach 0 or lower, the character dies
    unless hit points can be raised to at least +1
    by the end of the following round.
    @see v6 p.68
    @see v6 p.71
--]]
local function OnHealthChanged(self, newhealth, oldhealth)
    self.inst:SetConscious(newhealth > 2)
    self.inst:SetDying(newhealth <= 0)
end

local function OnSanityChanged(self, newsanity, oldsanity)
end

local Attribute = Class(function(self, inst)
    self.inst = inst
end)

-- 6版、7版共用函数
local function GetPhysicalLevel(sum)
    if     sum < 65  then   return 1
    elseif sum < 85  then   return 2    -- 20
    elseif sum < 125 then   return 3    -- 40
    elseif sum < 165 then   return 4    -- 40
    elseif sum < 205 then   return 5    -- 40
    else                                -- 80
        local level = 5
        local delta = sum - 204
        delta = math.ceil(delta / 80)
        return level + delta
    end
end

local DB_CONSTANTS =
{
    [1] = -2,
    [2] = -1,
    [3] = 0,
    [4] = "1d4",
}

-- 6版、7版共用函数
local function getdamagebonus(sum)
    local level = GetPhysicalLevel(sum)
    local db = DB_CONSTANTS[level]
    if level > 4 and db == nil then
        level = level - 4
        db = tostring(level) .. "d6"
    end
    --[[
    if type(db) == "string" then
        return Dice(db)
    else
        return db
    end
    --]]
    return tostring(db)
end

--{ Getters
function Attribute:GetCanMove()
    return self.str > 0 and self.dex > 0
end
function Attribute:GetLuck()
    return self.luck:get()
end
function Attribute:GetDamageBonus()
    local str = self.str
    local siz = self.siz
    local sum = str + siz
    return getdamagebonus(sum)
end
function Attribute:GetBuild()
    local str = self.str
    local siz = self.siz
    local sum = str + siz
    return GetPhysicalLevel(sum) - 3
end
function Attribute:GetMaxDamageBonus()
    local db = self:GetDamageBonus()
    if type(db) == "number" then return db end
    assert(type(db) == "string", "Invalid value type!")
    local i, j, max = string.find(db, "^%d+d(%d+)$")
    if max then return max end
    return tonumber(db)
end
function Attribute:GetMaxHP()
    return (self.con + self.siz) // 10
end
-- 魔法值
function Attribute:GetMaxMP()
    return self.pow // 5
end
-- 理智值
function Attribute:GetMaxSanity()
    return self.pow:get()
end
function Attribute:GetMinAge()
    return 15
end
function Attribute:GetMaxAge()
    return 90
end
function Attribute:GetMaxMove()
    local str = self.str
    local dex = self.dex
    local siz = self.siz
    local age = self.age
    local mov

    -- 敏捷和力量都小于体型
    if dex < siz and str < siz then
        mov = 7
    -- 敏捷和力量都大于体型
    elseif dex > siz and str > siz then
        mov = 9
    else
        mov = 8
    end
    if age < 40 then
        return mov
    else
        local delta = age - 39
        delta = math.ceil(delta / 10)
        return mov - delta
    end
end
function Attribute:GetOccupationPoint()
    return self.edu * 4
end
function Attribute:GetInterestPoint()
    return self.int * 2
end
--}

-- 设置年龄
function Attribute:SetAge(age, quiet)
    -- 6版规则规定 年龄 必须大于 教育+6
    -- 7版规则规定 年龄 必须大于或等于 15 且小于 90
    if age >= self:GetMinAge() and age < self:GetMaxAge() then
        self.age = age
        if not quiet then
            print("Detect age change !!!")
            OnAgeChanged(self)
        end
        return true
    end
    return false
end

-- sex: string
function Attribute:SetSex(sex)
    self.sex = sex
end

function Attribute:GetSex()
    return self.sex
end

function Attribute:SetName(name)
    self.name = name
end

function Attribute:GetName()
    return self.name
end

function Attribute:SetData(data)
    self.college = data.college
    self.degrees = data.degrees
    self.birthplace = data.birthplace
    self.marks = data.marks
    self.scars = data.scars
    self.mental_disorders = data.mental_disorders
end

return Attribute
