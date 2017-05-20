
AttrGen = Class(function(self)
end)

-- COC v7
AttrGen.ENTRIES =
{
    -- 力量 strength
    STR = "3d6*5",
    -- 体质 constitution
    CON = "3d6*5",
    -- 体型 size
    SIZ = "(2d6+6)*5",
    -- 敏捷 dexterity
    DEX = "3d6*5",
    -- 外貌 appearance
    APP = "3d6*5",
    -- 智力 intelligence
    INT = "(2d6+6)*5",
    -- 意志 power
    POW = "3d6*5",
    -- 教育 education
    EDU = "(2d6+6)*5",
    -- 幸运 luck
    LUCK = "2#3d6*5",
}

--{
local function TryGet(obj)
    if type(obj) == "number" then
        return obj
    elseif obj == nil then
        return 0
    end
    return obj:get()
end
local AttrField = Class(function(self, inst, dice)
    self.inst           = inst
    self.value          = dice and { [1] = dice }
end)
function AttrField:__add(value)
    return TryGet(value) + self:get()
end
function AttrField:__mul(value)
    return TryGet(value) * self:get()
end
function AttrField:__div(value)
    return self:get() / TryGet(value)
end
function AttrField:__idiv(value)
    return self:get() // TryGet(value)
end
function AttrField:__eq(value)
    return TryGet(value) == self:get()
end
function AttrField:__lt(value)
    return self:get() < TryGet(value)
end
function AttrField:get()
    return self.value[#self.value]
end
function AttrField:set(value, index)
    self.value[index or #self.value] = TryGet(value)
    self:OnChanged()
    return self
end
function AttrField:delta(value)
    self:set(self:get() + TryGet(value))
    return self
end
function AttrField:dup()
    self.value[#self.value + 1] = self:get()
    return self
end

local AttrSTR = AttrField

local AttrCON = Class(AttrField, function(self, inst, dice)
    AttrField._ctor(self, inst, dice)
end)
function AttrCON:OnChanged()
    if self:get() <= 0 then
        self.inst:SetDead(true)
    end
end

local AttrSIZ = Class(AttrField, function(self, inst, dice)
    AttrField._ctor(self, inst, dice)
end)
function AttrSIZ:OnChanged()
    if self:get() <= 0 then
        self.inst:SetVisible(false)
        self.inst:SetDead(true)
    end
end

local AttrDEX = AttrField

local AttrAPP = AttrField

local AttrINT = Class(AttrField, function(self, inst, dice)
    AttrField._ctor(self, inst, dice)
end)
function AttrINT:OnChanged()
    self.inst:SetStupid(self:get() <= 0)
end

local AttrPOW = AttrField

local AttrEDU = Class(AttrField, function(self, inst, dice)
    AttrField._ctor(self, inst, dice)
    -- age amend list
    self.fix = {}
end)
function AttrEDU:get()
    local res = self:getraw()
    -- sum fixes
    for i, v in ipairs(self.fix) do
        res = res + v
    end
    -- no more EDU than 99
    if res > 99 then
        res = 99
    end
    return res
end
function AttrEDU:getraw()
    return AttrField.get(self)
end

local function max(dice, ...)
    for i, v in ipairs{...} do
        if v > dice then
            dice = v
        end
    end
    return dice
end
local AttrLUCK = Class(AttrField, function(self, inst, dice, ...)
    AttrField._ctor(self, inst)
    self.first = dice
    self.large = max(dice, ...)
end)
function AttrLUCK:get()
    local age = self.inst.components.attribute.age
    return age < 20 and self.large or self.first
end
--}

function AttrGen:Generate(inst, count)
    --print("Try to generate "..tostring(count).." sets of attributes")
    count = count or TUNNING.DEFAULT_ATTRIBUTE_GENERATION_LIMIT
    self.list = {}
    for i = 1, count do
        self.list[i] =
        {
            str = AttrSTR(inst, Dice(AttrGen.ENTRIES.STR)),
            con = AttrCON(inst, Dice(AttrGen.ENTRIES.CON)),
            siz = AttrSIZ(inst, Dice(AttrGen.ENTRIES.SIZ)),
            dex = AttrDEX(inst, Dice(AttrGen.ENTRIES.DEX)),
            app = AttrAPP(inst, Dice(AttrGen.ENTRIES.APP)),
            int = AttrINT(inst, Dice(AttrGen.ENTRIES.INT)),
            pow = AttrPOW(inst, Dice(AttrGen.ENTRIES.POW)),
            edu = AttrEDU(inst, Dice(AttrGen.ENTRIES.EDU)),
            luck = AttrLUCK(inst, Dice(AttrGen.ENTRIES.LUCK)),
        }
    end
    --print(tostring(count).." sets of attributes have been generated.")
end

function AttrGen:Choose(index)
    if 1 <= index and index <= #self.list then
        self.choice = self.list[index]
        return true
    end
end

function AttrGen:UpdateComponents(inst, age)
    if inst and inst.components.attribute and age and self.choice then
        local attr = inst.components.attribute
        for k, v in pairs(self.choice) do
            attr[k] = v
            v.inst = inst
        end
        attr:SetAge(age, true)
    end
end
