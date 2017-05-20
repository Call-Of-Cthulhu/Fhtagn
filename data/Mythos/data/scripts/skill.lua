SKILLS = {}
SKLMAP = {}

local function addchild(parent_name, child_name)
    local map = SKLMAP[parent_name]
    if map == nil then
        map = {
            _count = 0
        }
        SKLMAP[parent_name] = map
    end
    if map[child_name] then
        return
    end
    map[child_name] = true
    map._count = map._count + 1
end

local function validatestring(key)
    assert(type(key) == "string")
    STRINGS.validate("SKILLS", key)
end

--[[
@param name : string, 技能名
@param era  : number, 时代
--]]
Skill = Class(function(self, name, odds, era)
    validatestring(name)
    self.name           = name
    self.odds           = odds or 0
    self.era            = era or 0
    self.canuse         = true

    SKILLS[name]        = self
end)

function Skill.validate()
    for k, v in pairs(SKILLS) do
        if v.parent then
            local parent = SKILLS[v.parent]
            if parent == nil then
                return false
            end
        end
        if v.oppo then
            for e, _ in pairs(v.oppo) do
                if SKILLS[e] == nil then
                    return false
                end
            end
        end
    end
    return true
end

--[[
@param canuse: boolean or function(self)
--]]
function Skill:SetCanUse(canuse)
    if type(canuse) == "boolean" or type(canuse) == "function" then
        self.canuse = canuse
        return self
    else
        error("Invalid parameter type")
    end
end

function Skill:GetCanUse()
    local canuse
    if self.hidden or self.spec then
        return false
    end
    if type(self.canuse) == "boolean" then
        canuse = self.canuse
    elseif type(self.canuse) == "function" then
        canuse = self.canuse(self)
    end
    return canuse
        and COC_ERA >= self.era     -- a skill is only available in right era
        and self.odds ~= nil        -- a skill without 'odds' is not available
end

function Skill:SetHidden(hidden)
    self.hidden = hidden
    return self
end
-- 设置回调函数，大成功
function Skill:SetOnCritical(fn)
    self.oncritical = fn
    return self
end
-- 设置回调函数，极难成功
function Skill:SetOnExtreme(fn)
    self.onextreme = fn
    return self
end
-- 设置回调函数，困难成功
function Skill:SetOnHard(fn)
    self.onhard = fn
    return self
end
-- 设置回调函数，普通成功
function Skill:SetOnSuccess(fn)
    self.onsuccess = fn
    return self
end
-- 设置回调函数，失败
function Skill:SetOnFailure(fn)
    self.onfailure = fn
    return self
end
-- 设置回调函数，大失败
function Skill:SetOnFumble(fn)
    self.onfumble = fn
    return self
end
-----------------------------------------------------------
-- 专精
Major = Class(Skill, function(self, skill, name, odds, era)
    validatestring(skill)
    Skill._ctor(self, name, odds, era)
    self.parent = skill
    addchild(skill, name)
end)

function Skill:GetChildren(cb)
    local map = SKLMAP[self.name]
    local children = {}
    for k, _ in pairs(map) do
        if cb == nil or cb(k, SKILLS[k]) then
            table.insert(children, k)
        end
    end
    return children
end
--------------------
-- Combat skills can't be pushed
function Skill:SetCombatSkill(combat)
    self.combat = combat
    return self
end

function Skill:IsCombatSkill()
    return self.combat
end

function Major:IsCombatSkill()
    return self.parent:IsCombatSkill()
end
--------------------
-- Set opposing skill decides difficulty level
function Skill:SetOppoSkills(...)
    self.oppo = {}
    for i, v in ipairs{...} do
        if type(v) == "string" then
            self.oppo[v] = v
        end
    end
    return self
end

function Skill:GetOppoSkills()
    return self.oppo
end

function Major:GetOppoSkills()
    return self.parent.oppo
end
-- Set as a specialization
function Skill:SetSpec(spec)
    self.spec = spec
    return self
end

local function IsNameSpec(name)
    for k, _ in pairs(SKLMAP) do
        if k == name then
            return true
        end
    end
end
function Skill.IsSpec(obj)
    if obj == nil then error("Argument is nil!") end
    if type(obj) == "string" then
        return IsNameSpec(obj)
    elseif type(obj) == "table" then
        if type(obj.name) ~= "string" then
            error("Invalid argument type: wrong table!")
        end
        if obj.spec then return true end
        return IsNameSpec(obj.name)
    else
        error("Invalid argument type: neither a table nor a string!")
    end
end

return require("skills.v"..tostring(COC_VERSION)) and Skill.validate()
