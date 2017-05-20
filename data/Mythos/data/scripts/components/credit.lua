-- 生活水平
local LIVING_CONDITION =
{
    -- 信用等级 0：         身无分文
    [1] = {
        -- 住所：           大概只有睡大街
        housing = 0,
        -- 出行：           步行、逃票
        travel  = table.pack("WALK", "EVADE_TICKET"),
        cash    = {
            [1920] = 0.5,               [2000] = 10,
        },
        assets  = nil,
        expense = {
            [1920] = 0.5,               [2000] = 10,
        },
    },
    -- 信用等级 1 - 9：     贫穷
    [2] = {
        -- 住所：           最廉价的出租屋或者睡袋旅馆
        housing = 1,
        -- 出行：           公共交通
        travel  = table.pack("PUBLIC_TRANSPORT"),
        cash    = {
            [1920] = "CRx1",            [2000] = "CRx20",
        },
        assets  = {
            [1920] = "CRx10",           [2000] = "CRx200",
        },
        expense = {
            [1920] = 2,                 [2000] = 40,
        },
    },
    -- 信用等级 10 - 49：   标准
    [3] = {
        -- 住所：           普通的家或公寓，外出住普通的旅馆 
        housing = 2,
        -- 出行：           普通旅行方式。（现代）会有一辆私家车。
        travel  = table.pack("LOW_END_AUTO"),
        cash    = {
            [1920] = "CRx2",            [2000] = "CRx40",
        },
        assets  = {
            [1920] = "CRx50",           [2000] = "CRx1000",
        },
        expense = {
            [1920] = 10,                [2000] = 200,
        },
    },
    -- 信用等级 50 - 89：   小康
    [4] = {
        -- 住所：           真材实料的住地，也许会有一些仆人（管家、主妇、清洁工、园丁，等等）
        --                  乡下估计还有小别墅。
        --                  外出会住昂贵的宾馆。
        housing = 3,
        -- 出行：           头等舱。会买高档车。
        travel  = table.pack("FIRST_CLASS_CABIN", "HIGH_END_AUTO"),
        cash    = {
            [1920] = "CRx5",            [2000] = "CRx100",
        },
        assets  = {
            [1920] = "CRx500",          [2000] = "CRx10000",
        },
        expense = {
            [1920] = 50,                [2000] = 1000,
        },
    },
    -- 信用等级 90+：       富裕
    [5] = {
        -- 住所：           豪华住所和有着大量仆人的庭院。
        --                  乡下和别处有着别墅是定范。
        --                  外出住总统套房。
        housing = 4,
        travel  = {},
        cash    = {
            [1920] = "CRx20",           [2000] = "CRx400",
        },
        assets  = {
            [1920] = "CRx2000",         [2000] = "CRx40000",
        },
        expense = {
            [1920] = 250,               [2000] = 5000,
        },
    },
    -- 信用等级 99：        豪富
    --                      与富裕差不多，但钱已经只是一个代号了。你将是世界上最富有的人。
    [6] = {
        housing = 5,
        travel  = table.pack("ANY"),
        cash    = {
            [1920] = 50000,             [2000] = 1000000,
        },
        assets  = {
            [1920] = 5000000,           [2000] = 100000000,
        },
        expense = {
            [1920] = 5000,              [2000] = 100000,
        },
    }
}

local function getcreditlevel(self)
    local credit = self.credit
    if      credit == 0 then
        return 1
    elseif  credit < 10 then
        return 2
    elseif  credit < 50 then
        return 3
    elseif  credit < 90 then
        return 4
    elseif  credit < 99 then
        return 5
    else
        return 6
    end
end

local Credit = Class(function(self, inst)
    self.inst = inst
    self.credit = 0
    self.cash = 0
end)

local function ParseCR(credit, value)
    -- CRxVALUE
    return type(value) == "string"
        and tonumber(string.sub(value, 4)) * credit
        or  value
        or  0
end

-- setters
function Credit:SetCredit(credit)
    self.credit = credit
    local level = getcreditlevel(self)
    local property = LIVING_CONDITION[level]
    local cash = property.cash[COC_ERA]
    self.cash = ParseCR(credit, cash)
    local assets = property.assets[COC_ERA]
    self.assets = ParseCR(credit, assets)
    local expense = property.expense[COC_ERA]
    self.expense = ParseCR(credit, expense)
end

function Credit:SetCash(cash)
    self.cash = cash
end

-- getters
function Credit:GetCredit()
    return self.credit
end

function Credit:GetCash()
    return self.cash
end

return Credit
