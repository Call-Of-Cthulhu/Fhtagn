local SkField = Class(function(self, parent, name, op, ip, pl)
    self.parent = parent
    self.name = name
    self.skill = SKILLS[name]
    assert(parent and name and self.skill, "Invalid argument!")
    -- 职业点数
    self.op = op or 0
    -- 兴趣点数
    self.ip = ip or 0
    -- 后期技能提升
    self.pl = pl or 0
end)

function SkField:OnSave()
    return {
        name = self.name,
        op = self.op,
        ip = self.ip,
        pl = self.pl
    }
end

function SkField:OnLoad(data)
    self.op = data.op
    self.ip = data.ip
    self.pl = data.pl
end

function SkField:get(self)
    return self.skill.odds + self.op + self.ip
end

function SkField:__index(key)
    return rawget(self, skill)[key]
end

function SkField:__newindex(key, value) end

function SkField:__eq(value)
    return value == self:get()
end

function SkField:__lt(value)
    return value > self:get()
end

function SkField:set(op, ip, pl)
    self.op = op or self.op
    self.ip = ip or self.ip
    self.pl = pl or self.pl
end

local Skill = Class(function(self, inst)
    self.inst = inst
    rawset(self, "__", {})
end)

function Skill:SetSkill(name, op, ip, pl)
    local field = rawget(self["__"], name)
    if field == nil then
        rawset(self["__"], name, SkField(self, name, op, ip, pl))
    elseif op != 0 or ip != 0 or pl != 0 then
        field:set(op, ip, pl)
    else
        rawset(self["__"], name, nil)
    end
end

function Skill:__index(name)
    return rawget(self["__"], name) or SKILLS[name]
end
-- 禁止操作
function Skill:__newindex(key, value) end

return Skill
