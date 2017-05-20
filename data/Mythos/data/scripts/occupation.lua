require "skill"
-- @see Page 41 "Alternate Ways"
-- 职业
OCCUPATIONS = {}
OCCUPATION_COUNT = 0

local DYNAMIC_TYPE = "__name" -- change this if C function ParseSkillList is changed

local function getname(name)
    return STRINGS["OCCUPATIONS"][name]["NAME"]
end
local function getdesc(name)
    return STRINGS["OCCUPATIONS"][name]["DESC"] or ""
end
local function checkskill(name)
    if name == nil then return end
    if name == '*' then return end
    assert(type(name) == "string")
    STRINGS.validate("SKILLS", name)
end
local function log(self)
    print("============================== Occupation ===============================")
    print(string.format("ID   : %s", self.name))
    print(string.format("Name : %s", getname(self.name)))
    print(string.format("Skill: %s", self:GetSkillString()))
end

--{
Occupation = Class(function(self, name, skills)
    if name == nil then
        error("Invalid argument 'name': nil!")
    end
    if skills == nil then
        error("Invalid argument 'skills': nil!")
    end
    self.name = name
    self.skills = skills
    OCCUPATIONS[name] = self
    OCCUPATION_COUNT = OCCUPATION_COUNT + 1
    -- validate localisation
    local result = ParseSkillList(skills)
    for k, v in pairs(result) do
        if k ~= DYNAMIC_TYPE then
            checkskill(k.skill)
            checkskill(k.major)
            for i, s in ipairs(k) do
                checkskill(s.skill)
                checkskill(s.major)
            end
        end
    end

    --log(self)
end)

-- 设置职业的信誉范围
function Occupation:SetCR(min, max)
    self.cr_min = min
    self.cr_max = max
    return self
end

-- 设置职业的技能点公式
-- 默认使用 components/attribute 中 Attribute:GetOccupationPoint() 返回的数值，即 EDU x4
function Occupation:SetOP(fn)
    if type(fn) == "function" then
        self.op = fn
    elseif type(fn) == "string" then
        fn = string.gsub(fn, "x", "*")
        fn = string.gsub(fn, "|", ",")
        fn = string.gsub(fn, "%(", "math.max(")
        for m in string.gmatch(fn, "%u+") do
            fn = string.gsub(fn, m, "attr." .. string.lower(m) .. ":get()")
        end
        fn = "return function(inst)\n\tlocal attr = inst.components.attribute\n\treturn ("..fn..")\nend"
        self.op = eval(fn)
    end
    return self
end

-- 设置职业出现的时代
function Occupation:SetEra(era)
    self.era = era
    return self
end

function Occupation:GetSkillString()
    local result = ParseSkillList(self.skills)
    local num2str =
    {
        [1] = "一",
        [2] = "二",
        [3] = "三",
        [4] = "四",
    }
    local buff = ""
    local bany = nil

    local TEXT_TOKEN_SEPARATOR = "; "
    local TEXT_OTHER_PREFIX = "自选"
    local TEXT_OTHER_SUFFIX = "技能"
    local TEXT_SOCIAL = "种社交技能(魅惑、话术、威吓或说服)"
    local TEXT_ANY = "任"
    local TEXT_LIST_PREFIX = "从"
    local TEXT_LIST_SEPARATOR = ", "
    local TEXT_LIST_SUFFIX = "中任选"
    local TEXT_LIST_END = "种技能"
    local function localise(name)
        return STRINGS.SKILLS[name].NAME
    end
    local function separate()
        if buff and #buff > 0 then
            buff = buff..TEXT_TOKEN_SEPARATOR
        end
    end

    for k, v in pairs(result) do
        if k ~= DYNAMIC_TYPE then
            v = tonumber(v)

            -- get dynamic type of table
            local t = k[DYNAMIC_TYPE]
            if t == "Skill" then
                if k.skill == '*' then
                    bany = TEXT_OTHER_PREFIX..num2str[v]..TEXT_OTHER_SUFFIX

                elseif k.skill == "SOCIAL" then
                    separate()
                    buff = buff..num2str[v]..TEXT_SOCIAL

                else
                    separate()
                    buff = buff..localise(k.skill)
                    -- check if this skill is specialization
                    if Skill.IsSpec(k.skill) then
                        buff = buff..'('
                        if k.major then
                            buff = buff..localise(k.major)
                        else
                            buff = buff..TEXT_ANY..num2str[v]
                        end
                        buff = buff..')'
                    -- only append count number if it's larger than 1
                    elseif v > 1 then
                        buff = buff..'('..TEXT_ANY..num2str[v]..')'
                    end
                end
            else
                -- this key is a list of skills
                local list = nil
                for i, s in ipairs(k) do
                    if list == nil then
                        list = TEXT_LIST_PREFIX
                    else
                        list = list..TEXT_LIST_SEPARATOR
                    end

                    if s.major then
                        list = list..localise(s.skill)..'('..localise(s.major)..')'
                    else
                        list = list..localise(s.skill)
                    end
                end
                separate()
                buff = buff..list..TEXT_LIST_SUFFIX..num2str[v]..TEXT_LIST_END
            end
        end
    end
    if bany ~= nil then
        buff = buff..TEXT_TOKEN_SEPARATOR..bany
    end

    return buff
end
--}

require("occupations/v"..tostring(COC_VERSION))
