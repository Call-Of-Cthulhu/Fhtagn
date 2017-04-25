require("class")

--{
local OnAgeChanged
if COC_VERSION == 6 then
    --(
    OnAgeChanged = function(self)
        local age = self.age
        local delta = age - self:GetMinAge()
        delta = math.floor(delta / 10)
        -- add a point of EDU
        self.edu:delta(delta)
        -- additional 20 occupation points
        -- TODO
        -- mortality
        delta = age - 40
        delta = math.floor(delta / 10)
        PopupAgePunishment(delta, self.str,
                self.con, self.dex, self.app)
    end
    --)
elseif COC_VERSION == 7 then
    --(
    -- 教育增强检定
    -- 7版
    local function DoEducate(self, count)
        local edu = self.edu
        local fix = edu.fix
        local src = #fix + 1
        if src >= count then
            return false
        end
        for i = src, count do
            local dice = Dice("1d100")
            if dice > edu:get() then
                local delta = Dice("1d10")
                fix[i] = delta
            end
        end
        return true
    end
    -- 衰老 属性惩罚
    -- 7版
    local function DoAge(self, adjust, dapp)
        PopupAgePunishment(adjust, self.str, self.con, self.dex)
        self.app:delta(dapp)
    end
    --)(
    OnAgeChanged = function(self, doeducate)
        local age = self.age
        local str = self.str
        local con = self.con
        local siz = self.siz
        local dex = self.dex
        local app = self.app
        local int = self.int
        local pow = self.pow
        local edu = self.edu

        str:dup()
        con:dup()
        siz:dup()
        dex:dup()
        app:dup()
        int:dup()
        pow:dup()
        edu:dup()
        if 15 <= age and age <= 19 then
            str:delta(-5)
            siz:delta(-5)
            edu:delta(-5)
            self.luck = math.max(table.unpack(self.luck))
        else
            self.luck = self.luck[0]
            -- FIXME
            if 20 <= age and age <= 39 then
                if doeducate then
                    self.edu[2] = DoEducate(self.edu[1], 1)
                end
            elseif 40 <= age and age <= 49 then
                if doeducate then
                    self.edu[2] = DoEducate(self.edu[1], 2)
                end
            elseif 50 <= age and age <= 59 then
                if doeducate then
                    self.edu[2] = DoEducate(self.edu[1], 3)
                end
                DoAge(self, 10, 10)
            elseif 60 <= age and age <= 69 then
                if doeducate then
                    self.edu[2] = DoEducate(self.edu[1], 4)
                end
                DoAge(self, 20, 15)
            elseif 70 <= age and age <= 79 then
                if doeducate then
                    self.edu[2] = DoEducate(self.edu[1], 4)
                end
                DoAge(self, 40, 20)
            elseif 80 <= age and age <= 89 then
                if doeducate then
                    self.edu[2] = DoEducate(self.edu[1], 4)
                end
                DoAge(self, 80, 25)
            end
        end
    end
    --)
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
    if newhealth <= 2 then
        self.inst:SetConscious(false)
    end
    if newhealth <= 0 then
        self.inst:SetDying(true)
    end
end

local function OnSanityChanged(self, newsanity, oldsanity)
end

--{
INCOME = {}
if COC_VERSION == 6 then
    INCOME[1890] = table.pack(500, 1000, 1500, 2000, 2500, 3000, 4000, 5000, 5000, 10000)
    INCOME[1920] = table.pack(1500, 2500, 3500, 3500, 4500, 5500, 6500, 7500, 10000, 20000)
    -- 现代
    INCOME[2000] = table.pack(15000, 25000, 35000, 45000, 55000, 75000, 100000, 200000, 300000, 500000)
end
--}

--{
local AttrField = Class(function(self, parent, dice)
    self.parent = parent
    self.value = { [1] = dice }
end)

function AttrField:get()
    return self.value[#self.value]
end

function AttrField:set(value, index)
    self.value[index or #self.value] = value
    self:OnChanged()
end

function AttrField:delta(value)
    self:set(self:get() + value)
end

function AttrField:dup()
    -- suppress OnChanged
    self.value[#self.value + 1] = self:get()
    return self
end

--(
local AttrSTR = Class(AttrField)
function AttrSTR:OnChanged()
    if self:get() <= 0 then
        self.parent.inst:SetCanMove(false)
    end
end
--)(
local AttrCON = Class(AttrField)
function AttrCON:OnChanged()
    if self:get() <= 0 then
        self.parent.inst:SetDead(true)
    end
end
--)(
local AttrSIZ = Class(AttrField)
function AttrSIZ:OnChanged()
    if self:get() == 0 then
        self.parent.inst:SetVisible(false)
        self.parent.inst:SetDead(true)
    end
end
--)(
local AttrDEX = Class(AttrField)
function AttrDEX:OnChanged()
    if self:get() == 0 then
    end
end

local AttrAPP = Class(AttrField)
function AttrAPP:OnChanged()
    if self:get() == 0 then
    end
end

local AttrINT = Class(AttrField)
function AttrINT:OnChanged()
    if self:get() == 0 then
    end
end

local AttrPOW = Class(AttrField)

local AttrEDU = Class(AttrField, function(self, parent, dice)
    AttrField._ctor(self, parent, dice)
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
function AttrEDU:OnChanged()
    if self:get() == 0 then
    end
end
--)
--}

local Attribute = Class(function(self, inst)
    self.inst = inst
end)

--{
if COC_VERSION == 6 then
    --(
    --[[ Alternate Way
     * Always roll too low?
        With your keeper's agreement, use a roll of 2d6+6
        rather than 3d6. Retain the EDU roll at 3d6+3
    --]]
    function Attribute:Generate(easy)
        --[[ 力量 strength
         * Strength measures the muscle power of investigators.
            Use it to judge how much they can lift, or push or pull,
            or how tightly they can cling to something.
            This characteristic is important in
            determining the damage investigators do
            in hand-to-hand combat.
         * Reduced to Strength 0, an investigator is an invalid,
            unable to leave his or her bed.
        --]]
        self.str = AttrSTR(self, Dice(easy and "2d6+6" or "3d6"))
        --[[ 体质 constitution
         * This compares health, vigor, and vitality.
         * Constitution also helps calculate how well
            investigators resist drowning or suffocation.
         * Poisons and diseases may directly challenge
            investigator Constitutions.
         * High-CON investigators often have higher hit points,
            the better to resist injury and attack.
         * Serious physical injury or magical attack might lower CON.
         * If Constitution reaches 0, the investigator dies!
        --]]
        self.con = AttrCON(self, Dice(easy and "2d6+6" or "3d6"))
        --[[ 体型 size
         * The characteristic SIZ averages height and weight
            into one number.
         * To see over something, to squeeze through a small opening,
            or even to judge whose head might be
            sticking up out of the grass, use Size.
         * Size helps determine hit points and the damage bonus.
         * One might decrease SIZ to indicate loss of several limbs,
            though lowering DEX is more often the solution.
         * Presumably if investigators lose all SIZ,
            they disappear —— goodness knows to where.
        --]]
        self.siz = AttrSIZ(self, Dice("2d6+6"))
        --[[ 敏捷 dexterity
         * Investigators with higher Dexterity scores are quicker,
            <nimbler>, and more physically flexible.
         * A keeper might call for a DEX roll in order to grab
            a support to keep from falling, to stay upright
            in high winds or on ince, to accomplish some
            dedicate task, or to take something without being noticed.
         * As with the other characteristics, the difficulty of
            the roll depends on the multiplier which the keeper
            selects for the characteristic.
         * An investigator without DEX is uncoordinated,
            unable to perform physical tasks without also receiving
            a successful Luck roll.
         * In combat, the character with the higher DEX hits
            or fires first, and thus may be able to disarm or disable
            an opponent before the foe can attack.
         * DEX x2 determines the starting percentage of investigator
            Dodge skills.
        --]]
        self.dex = AttrDEX(self, Dice(easy and "2d6+6" or "3d6"))
        --[[ 外貌 appearance
         * Appearance shows attractiveness and friendliness.
         * Some multiple of APP might be useful in social encounters,
            or when trying to make an initial impression on
            a number of the opposite sex,
            perhaps in conjunction with a Fast Talk or Bargain roll.
         * Appearance is a surface characteristic, however:
            initial impressions are not necessarily lasting.
         * APP measures what one sees in the mirror, not ongoing
            personal leadership or <charisma>.
         * An investigator without APP is <appallingly> ugly,
            provoking comment and shock everywhere.
        --]]
        self.app = AttrAPP(self, Dice(easy and "2d6+6" or "3d6"))
        --[[ 智力 intelligence
         * Intelligence represents how well investigators learn,
            remember, and analyze, and of how aware they are of
            that which is around them.
         * To help describe different circumstances,
            keepers multiply INT times various numerals and then
            call for D100 rolls equal to or less than the products.
            INT x5 —— the Idea roll —— is especially popular.
         * Difficult concepts, plans, or inspired guesses
            have lower chances to be derived, and hence
            get lower multipliers, down to INT x2 or IN2 x1.
            Such rolls can establish whether or not
            an investigator makes a deducation or links information,
            avoiding the question of the player deducing (for instance)
            that the presence of a volcano argues that
            a world has a molten core.
         * An investigator without INT is a babbling, drooling idiot.
         * If the amount of Intelligence seems to <contradict>
            a characteristic rolled later, that's another chance
            for roleplaying: an investigator with high EDU and low INT,
            for instance, might be a <pedantic> teacher or
            a sideshow performer, someone who knows facts
            but not their meanings.
         * Conversely, high INT and low EDU might mean ignorance ——
            a farm boy or poor immigrant, new to the Big City ——
            but this person would not be <dull-witted>.
        --]]
        self.int = AttrINT(self, Dice("2d6+6"))
        --[[ 意志 power
         * Power indicates force of will.
         * The higher the POW, the higher the aptitude for magic.
         * Power does not quantify leadership,
            which is a matter for roleplaying.
         * The amount of Power or the number of magic points
            (they derive from Power) measure resistance to
            magical or <hypnotic> attack.
         * An investigator without POW is zombie-like and
            unable to use magic. Unless stated otherwise,
            lose POW is lost permanently.
         * POW x5 is the Luck roll, about which see further below.
         * That amount also equals a character's
            initial SAN characteristic.
         * Magic points, unlike Power, are spent and regenerated.
         * The POW of ordinary chracter rarely changes.
         * One who is <adroit> in the magic of the Cthulhu Mythos
            may be able to increase personal POW.
            Keepers especially are referred to the boxes text
            titled "How sorcerers Get That Way", on <v6 p.101>
        --]]
        self.pow = AttrPOW(self, Dice(easy and "2d6+6" or "3d6"))
        --[[ 教育 education
         * Education measures formal and factual knowledge
            possessed by the investigator, as well as the number of 
            years it took him or her to learn that material.
         * EDU measures information, not intelligent use of information.
         * EDU partly determines how many skill points an investigator has.
         * EDU x5 is the Know roll, about which see further below.
         * EDU x5 also represents the investigator's starting percentage
            with the skill "Own Language".
         * An investigator without EDU would be like a newborn baby,
            or an <amnesiac> without knowledge of the world,
            probably curious and <credulous>.
         * An EDU score of 12 suggests a high school graduate.
         * More than that indicates a person with some college years.
         * EDU greater than 16 indicates some graduate-level work or degree
         * An investigator without high Education may not be schooled,
            but still might be studious and observant.
         * See also the spread for "Creating Your Investigator",
            on v6 p.36-37
        --]]
        self.edu = AttrEDU(self, Dice("3d6+3"))
        -- 幸运 luck
        -- 6版规则规定幸运值由 POW 决定
        self.luck = nil
        -- 收入和财产 income and property
        -- The investigator also has property and other assets of value
        -- equal to 5 times yearly income.
        -- * One tenth of that is banked as cash.
        -- * Another one tenth is in stocks and bonds,
        --   convertible in 30 days
        -- * The remainder is in old books, a house, or whatever seems
        --   appropriate to the character
        self.income = INCOME[COC_ERA][Dice("1d10")]
    end
    --)
elseif COC_VERSION == 7 then
    --(
    function Attribute:Generate()
        -- 力量 strength
        self.str = AttrSTR(self, Dice("3d6") * 5)
        -- 体质 constitution
        self.con = AttrCON(self, Dice("3d6") * 5)
        -- 体型 size
        self.siz = AttrSIZ(self, Dice("2d6+6") * 5)
        -- 敏捷 dexterity
        self.dex = AttrDEX(self, Dice("3d6") * 5)
        -- 外貌 appearance
        self.app = AttrAPP(self, Dice("3d6") * 5)
        -- 智力 intelligence
        self.int = AttrINT(self, Dice("2d6+6") * 5)
        -- 意志 power
        self.pow = AttrPOW(self, Dice("3d6") * 5)
        -- 教育 education
        self.edu = AttrEDU(self, Dice("2d6+6") * 5)
        -- 幸运 luck
        self.luck = table.pack(Dice("3d6") * 5,
            Dice("3d6") * 5, Dice("3d6") * 5)
        -- 7版规则没有"收入/财产"设定
        self.income = nil
    end
    --)
end
--}

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

local DB_CONSTANTS
if COC_VERSION == 6 then
    DB_CONSTANTS =
    {
        [1] = "-1d6",
        [2] = "-1d4",
        [3] = 0,
        [4] = "1d4",
    }
elseif COC_VERSION == 7 then
    DB_CONSTANTS =
    {
        [1] = -2,
        [2] = -1,
        [3] = 0,
        [4] = "1d4",
    }
end

-- 6版、7版共用函数
local function getdamagebonus(sum)
    local level = GetPhysicalLevel(sum)
    if DB_CONSTANTS == nil or level < 1 then
        error("runtime")
    end
    local db = DB_CONSTANTS[level]
    if level > 4 and db == nil then
        level = level - 4
        db = tostring(level) .. "d6"
    end
    if type(db) == "string" then
        return Dice(db)
    else
        return db
    end
end

-- v7 体格
-- @see ? p.49
-- @see ? p.105 战技
local function getTG(sum)
    local tg = GetPhysicalLevel(sum) - 3
    return tg
end

--{ Getters
if COC_VERSION == 6 then        --(
    -- * If the deriving characteristics changes, the Idea, Luck,
    -- or Know roll changes immediately as well.
    -- * Similarly, hit points and the damage bonus change
    -- if the characteristics related to them change
    -- * Magic points might not change immediately.
    -- If excess points existed, they would have to be spent
    -- before maximum magic points need equal a new, lower POW.

    --[[ Idea
     * The Idea roll represents hunches and the ability
        to interpret the obvious.
        When no skill roll seems appropriate,
        this roll might show understanding of a concept or the ability
        to solve a pressing intellectual problem.
        The Idea roll is specially handy to show awareness:
        did the investigator observe and understand
        what he or she saw?
        Would a normal person have become aware of
        a particular feeling about a gathering or a place?
        Is anything out of place on that hill?
     * Save the Spot Hidden skill for specific clues or items
        not immediately noticeable. Employ the Psychology skill
        when dealing with individuals.
    --]]
    function Attribute:GetIdea()
        return self.int:get() * 5
    end
    --[[ Luck
     * Did the investigator bring along some particular piece of gear?
        Is he or she the one the dimensional shambler decides to attack?
        Did the investigator stop on the floorboard which breaks,
        or the one that squeaks?
        The Luck roll is a quick way to get an answer.
     * Luck is the ability to be in the right place at the right time:
        this roll is often called for in emergency situations,
        especially when the keeper desires higher percentage chances for
        the investigators, more than might result from, say,
        calling for Jump or Dodge rolls.
    --]]
    function Attribute:GetLuck()
        return self.pow:get() * 5
    end
    --[[ Know
     * All people know bits of information about different topics.
        The Know roll represents what's stored in the brain's
        intellectual attic, calculated as the percentage chance
        that the investigator's education supplied the information.
     * The investigator might know
        if one puts sulfuric acid into water
        or water into sulfuric acid
        (whether or not ever studying Chemistry)
        or be able to remember the geography of Tibet
        (without a Navigate roll),
        or know how many legs arachnids have
        (and possess only a point of Biology).
     * Identification of present-day earthly languages
        is an excellent use for the Know roll.
     * Since no one knows everything, the Know roll never exceeds
        99 even though an investigator might have EDU 21.
    --]]
    function Attribute:GetKnow()
        local know = self.edu:get() * 5
        return know < 100 and know or 99
    end
    --[[ Damage Bonus
     * All physical beings have a damage bonus.
        The term is confusing, because the 'bonus' may actually
        turn out to be a reduction, but the idea is simple:
        larger, stronger creatures
        on average do more physical damage
        than lesser, weaker brethren.
     * To determine a damage bonus, add STR to SIZ,
        and find the total in the Damage Bonus Table (v6 p.43).
        Each range of results correlates with a stated die or dice roll.
        In hand-to-hand combat, add the indicated roll
        to all the character's blows,
        whether using a natural weapon such as a fist
        or man-made weapon such as a club or knife,
        and whether striking a foe or some object (such as a door).

     * For thrown objects, add half the thrower's damage bonus
        to the injury or damage it does.
     * Do not add damage bonuses to firearms attacks,
        or to other attacks which are independent of STR and SIZ.
     * Keepers should not routinely add damage bonuses to Bite attacks.
     * For simplicity's sake, keepers might ignore
        damage bonuses for characters they run.
        Individual or average damage bonuses
        for creatures are always given in the rules.
    --]]
    function Attribute:GetDamageBonus()
        local str = self.str:get()
        local siz = self.siz:get()
        local sum = str + siz
        return getdamagebonus(sum * 5 + 5)
    end
    --[[ Hit Points
     * All physical beings have hit points.
     * Always apply the hit point loss before any loss to CON.
     * Lost hit points return naturally at the rate of
        '1D3' hit points per game week.
        The First Aid or Medicine skills can immediately restore
        '1D3' hit points as emergency treatment.
    --]]
    function Attribute:GetMaxHP()
        local con = self.con:get()
        local siz = self.siz:get()
        local sum = con + siz
        return math.floor(sum / 2)
    end
    --[[ Magic Points
     * Magic points might be spent casting spells
        or fighting off malign influences.
     * Magic points naturally regenerate:
        ALL can return in 24 hours.
        Prorate the return of partial losses.
     * Should an investigator's magic points reach 0,
        he or she is emotionally drained,
        and faints until 1 magic point regenerates.
     * Should POW decrease, magic points would not
        diminish until spent,
        whereupon they would return only to the new maximum.
        Should POW increase, magic points would begin
        a prorata increase immediately.
    --]]
    function Attribute:GetMaxMP()
        return self.pow:get()
    end
    --[[ SAN Sanity
     * Find Sanity by multiplying POW x5.
     * Sanity is derived, but it is crucial to investigators
        and central to the idea of this game.
     * An entire chapter in this section is devoted to Sanity:
        it distinguishes between the SAN characteristic,
        Sanity points, and maximum Sanity.
     * Sanity points <fluctuate>.
     * Characteristic SAN does NOT change.

     * An investigator's maximum of Sanity points is never more than 99.
     * Sanity points of 99 represent the strongest possible mind,
        one capable of <deflecting> or <lessening> even extreme
        emotional shocks.
     * On the other hand, 30 Sanity points would indicate
        a more fragile mind, one which might be
        driven into temporary or permanent madness.
     * Most Mythos monsters and some natural events cost Sanity points
        to encounter, and Mythos spells cost Sanity points
        to learn and to cast.
     * An investigator's Sanity points are never more than
        99 minus current Cthulhu Mythos percentiles.
     * Up to that maximum, it is possible to regain
        Sanity points lost, or even to increase Sanity points
        above the original total, but that process is slow.
    --]]
    function Attribute:GetMaxSanity()
        local max_sanity = self.pow:get() * 5
        local skill = self.inst.components.skill
        if skill == nil then
            return max_sanity
        end
        local skill_point = skill:GetSkillPoint("CTHULHU_MYTHOS")
        return math.min(max_sanity, 99 - skill_point)
    end
    function Attribute:GetMinAge()
        return self.edu:get()
    end
    function Attribute:GetMaxAge()
        return 90
    end
    function Attribute:GetOccupationPoint()
        local age = self:GetAge()
        local min = self:GetMinAge()
        local delta = age - min
        delta = math.floor(delta / 10)
        local bonus = delta * 20
        return self.edu:get() * 20 + bonus
    end
    function Attribute:GetInterestPoint()
        return self.int:get() * 10
    end
elseif COC_VERSION == 7 then    --)(
    function Attribute:GetLuck()
        return self.luck
    end
    function Attribute:GetDamageBonus()
        local str = self.str:get()
        local siz = self.siz:get()
        local sum = str + siz
        return getdamagebonus(sum)
    end
    --@see ? p.119
    function Attribute:GetMaxHP()
        local con = self.con:get()
        local siz = self.siz:get()
        local sum = con + siz
        return math.floor(sum / 10)
    end
    function Attribute:GetMaxMP()
        local pow = self.pow:get()
        return math.floor(pow / 5)
    end
    function Attribute:GetMinAge()
        return 15
    end
    function Attribute:GetMaxAge()
        return 90
    end
    function Attribute:GetMaxMove()
        local str = self.str:get()
        local dex = self.dex:get()
        local siz = self.siz:get()
        local age = self.age
        local mov

        if dex < siz and str < siz then
            mov = 7
        elseif dex > siz and str > size then
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
        return self.edu:get() * 4
    end
    function Attribute:GetInterestPoint()
        return self.int:get() * 2
    end
end                             --)
--}

-- 设置年龄
function Attribute:SetAge(age)
    -- 6版规则规定 年龄 必须大于 教育+6
    -- 7版规则规定 年龄 必须大于或等于 15 且小于 90
    if age >= self:GetMinAge() and age < self:GetMaxAge() then
        self.age = age
        OnAgeChanged(self)
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
