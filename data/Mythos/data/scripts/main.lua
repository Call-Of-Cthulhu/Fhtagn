function CheckCObject(name)
    local result = _G[name] and _G[name].__name == name
    local message = result and "[FOUND]" or "[LOST]"
    message = ("CObject '"..name.."' "..message)
    if result then
        print(message)
    else
        error(message)
    end
end

CheckCObject("TheSim")
--CheckCObject("TheNet")

-- Default Constants
COC_ERA     = 1920
COC_VERSION = 7

DEFAULT_SERVER_PORT = 2333

math.randomseed(os.time())

package.path = "data/Mythos/data/scripts/?.lua"

require "util"
require "class"

require "gamerules"
require "mainfunctions"
require "attrgen"
require "strings"
require "occupation"
require "entityscript"
--require "combat"
--require "books"
--require "magic"
--require "weapons"
--require "poisons"
--require "pursuit"
--require "sanity"
--require "diceresult"
--require "dicerequest"
--require "dicesession"
--require "keeper"
--require "prefabs"


Prefabs = {}
Ents    = {}
NumEnts = 0
------------------------ TEST ------------------------
local printf, scanf = io.printf, io.scanf
local function print_attr_table(list, src, len)
    src = src or 1
    len = len or #list
    print("====================================== 属 === 性 === 表 ============================================"..
        "\n||   ||力量(STR)|体质(CON)|体型(SIZ)|敏捷(DEX)||外貌(APP)|智力(INT)|意志(POW)|教育(EDU)|幸运(LUCK)||")
    for i = src, src + len - 1 do
        local attr = list[i]
        printf("||------------------------------------------------------------------------------------------------||"..
            "\n|| %i || %7i | %7i | %7i | %7i || %7i | %7i | %7i | %7i |  %7i ||\n",
            i, attr.str:get(),
            attr.con:get(),
            attr.siz:get(),
            attr.dex:get(),
            attr.app:get(),
            attr.int:get(),
            attr.pow:get(),
            attr.edu:get(),
            attr.luck:get())
    end
    print("====================================================================================================")
end
local function print_attr_misc(player)
    local attr = player.components.attribute
    printf( "======================================================================================================\n"..
            "||  职业点  |  兴趣点  |  幸运值  |  生命值  |  魔法值  |  理智值  |   体格   |  行动力  | 伤害加成 ||\n"..
            "||--------------------------------------------------------------------------------------------------||\n"..
            "|| %8i | %8i | %8i | %8i | %8i | %8i | %8i | %8i | %8s ||\n"..
            "======================================================================================================\n",
                    attr:GetOccupationPoint(),
                    attr:GetInterestPoint(),
                    attr:GetLuck(),
                    attr:GetMaxHP(),
                    attr:GetMaxMP(),
                    attr:GetMaxSanity(),
                    attr:GetBuild(),
                    attr:GetMaxMove(),
                    attr:GetDamageBonus()
    )
end
local function printblock(fmt, block)
    if fmt == nil then error("Argument 'fmt' is nil!") end
    if block == nil then error("Argument 'block' is nil!") end
    local pattern = "%%(\45?)([0-9]*)s"
    local p1, p2 = string.find(fmt, pattern)
    local prefix = string.sub(fmt, 1, p1 - 1)
    local suffix = string.sub(fmt, p2 + 1)
    for minus, width in string.gmatch(fmt, pattern) do
        minus = #minus > 0
        width = tonumber(width)
        local bsize = #block
        local nmark = 1
        while bsize > 0 do
            local nbits
            if bsize >= width then
                nbits = width
            else
                nbits = bsize
            end
            --print("Gonna print "..tostring(nbits).." characters ...")
            local line = string.sub(block, nmark, nmark + nbits - 1)
            local nwsc = width - nbits
            if nwsc > 0 then
                local wstr = string.rep(' ', nwsc)
                if minus then
                    line = line..wstr
                else
                    line = wstr..line
                end
            else assert(nwsc == 0)
            end
            line = prefix..line..suffix
            print(line)
            nmark = nmark + nbits
            bsize = bsize - nbits
        end
        return
    end
end
local function print_occupation_table()
    local nmax = 94
    print       ("====================================== 职 === 业 === 表 ============================================")
    printf      ("|| %-94s ||\n", string.format("%i occupation(s) loaded.", OCCUPATION_COUNT))
    for k, v in pairs(OCCUPATIONS) do
        local name = v.name
        local tran = STRINGS.OCCUPATIONS[name].NAME
        local line = tran..'('..name..')'
        local llen = string.getBytes(line)
        -- fill with white-space character
        local nwsc = nmax - llen
        print   ("----------------------------------------------------------------------------------------------------")
        print   ("|| "..line..string.rep(' ', nwsc).." ||")
        local skil = v.skills
        --printblock("|| %-94s ||", skil)
    end
    -- 100
    print       ("====================================================================================================")
end
local function Main()
    local attrgen = AttrGen()
    local player = CreateEntity()
    local attr = player:AddComponent("attribute")
    local age

    attrgen:Generate(player)

    printf("请输入角色姓名(PC): ")
    attr:SetName(scanf("%s"))

    printf("请选择角色性别(Sex):\t(1) 男性\t(2) 女性\t")
    attr:SetSex(scanf("%i"))

    while true do
        printf("请输入角色年龄(Age): ")
        age = scanf("%i")
        if attr:SetAge(age, true) then
            break
        else
            print("Invalid age! Please make sure your age is between "..tostring(attr:GetMinAge()).." and "..tostring(attr:GetMaxAge()).." !!!")
        end
    end

    print("已经自动为您随机生成了 "..tostring(#attrgen.list).." 组属性")
    print_attr_table(attrgen.list)
    printf("请从上面的随机属性中任选一个并输入序号: ")
    local chosen_attr = scanf("%i")
    while true do
        if chosen_attr ~= nil and attrgen:Choose(chosen_attr) then
            print("您选择了第 "..tostring(chosen_attr).." 组.")
            attrgen:UpdateComponents(player, age)
            print("以下是您的主要属性:")
            print_attr_table(attrgen.list, chosen_attr, 1)
            print("以下是您的派生属性:")
            print_attr_misc(player)
            printf("请输入 Y(es) 确认您的选择，输入 N(o) 返回选择: ")
            local confirm = scanf("%s")
            if confirm == 'Y' or confirm == 'y' then
                break
            elseif confirm == 'N' or confirm == 'n' then
                chosen_attr = nil
            elseif confirm == 'q' then
                print()
                return
            else
                local confirm_num = tonumber(confirm)
                if confirm_num ~= nil and attrgen:Choose(confirm_num) then
                    chosen_attr = confirm_num
                end
            end
        else
            print_attr_table(attrgen.list)
            printf("请选择一个表中存在的序号: ")
            chosen_attr = scanf("%i")
        end
    end

    while true do
        print_occupation_table()
        printf("请从上面的职业列表中任选一个并输入英文代码: ");
        local chosen_occupation = scanf("%s")
        if OCCUPATIONS[chosen_occupation] ~= nil then
            break
        elseif chosen_occupation == nil then
            print()
            os.exit(0)
        else
            print("Invalid occupation!")
        end
    end

    --[[
    print("====================================== 技 === 能 === 表 ============================================")
    print("====================================================================================================")
    printf("请从上面的技能列表中任选一个并输入名称: ")
    --]]
    local command = scanf("%s")
    if command == "server start" then
    end
end

Main()

