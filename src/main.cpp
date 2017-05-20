/*
 * Author   : KaiserKatze
 * Date     : 2017-4-14
 * License  : GPLv3
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dirent.h>
#include <linux/limits.h>
#include <sys/types.h>
#include <sys/dir.h>
#include <unistd.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "TheSim.h"
#include "Error.hpp"

using namespace std;

// current release: Lua 5.3.4
int main(int count, char ** argv)
{
#ifdef DEBUG
    char path[PATH_MAX];

    getcwd(path, PATH_MAX);
    printf("Working directory: %s\n", path);
#endif
    try
    {
        TheSim sim {};
    }
    catch (Error * err)
    {
        err->PrintMessage();
        delete err;
    }

#ifdef DEBUG
    printf("Main process exits successfully :D\n");
#endif
    return EXIT_SUCCESS;
}

/*
typedef struct
{
    int STR; int CON; int SIZ; int DEX;
    int APP; int INT; int POW; int EDU;
    int LUCK;
} AttrTable;

#define GET_ATTR(VAR_NAME, FIELD_NAME) { \
    lua_getfield(L, -1, FIELD_NAME); \
    lua_getfield(L, -1, "get"); \
    res = lua_pcall(L, 1, 1, 0); \
    if (res != LUA_OK) throw res; \
    VAR_NAME = lua_tointegerx(L, -1, &res); \
    if (!res) throw LUA_ERRRUN; \
    (*atable_p)[i].VAR_NAME = int(VAR_NAME & 0xffff); }
static int GetAttrTable(lua_State * L, AttrTable ** atable_p)
{
    int res;
    int i, n;
    lua_Integer STR, CON, SIZ, DEX, APP, INT, POW, EDU, LUCK;

    res = lua_getglobal(L, "AttrGen"); // <1> class 'AttrGen'
    res = lua_pcall(L, 0, 0, 0); // <1> attrgen = AttrGen()
    if (res != LUA_OK)
        throw res;
    lua_getfield(L, -1, "Generate"); // <2>
    lua_pushvalue(L, -2); // <3>
    lua_pushnil(L); // <4>
    res = lua_pcall(L, 2, 0, 0); // <1> attrgen:Generate(nil)
    if (res != LUA_OK)
        throw res;
    lua_getfield(L, -1, "list"); // <2> self.list
    n = luaL_len(L, -1);
    *atable_p = (AttrTable *) malloc(n * sizeof(AttrTable));
    for (i = 0; i <= n; i++)
    {
        lua_geti(L, -1, i + 1); // self.list[i]
        GET_ATTR(STR, "str");
        GET_ATTR(CON, "con");
        GET_ATTR(SIZ, "siz");
        GET_ATTR(DEX, "dex");
        GET_ATTR(APP, "app");
        GET_ATTR(INT, "int");
        GET_ATTR(POW, "pow");
        GET_ATTR(EDU, "edu");
        GET_ATTR(LUCK, "luck");
        lua_pop(L, 1);
    }
    lua_pop(L, 2);
    return n;
}

#define PRINT_OCCUPATION() { \
    if (lua_next(L, -2) == 0) \
    { \
        lua_pop(L, 2); \
        break; \
    } \
    else \
    { \
        name = lua_tolstring(L, -2, &len); \
        lua_pop(L, 1); \
        printf("%16.*s\n", len, name); \
    } }
static int GetOccupationList(lua_State * L)
{
    const char * name;
    int len;

    lua_getglobal(L, "OCCUPATIONS");
    for (lua_pushnil(L);;)
    {
        PRINT_OCCUPATION();
    }
}

#define PRINT_SKILL() { \
    if (lua_next(L, -2) == 0) \
    { \
        lua_pop(L, 2); \
        break; \
    } \
    else \
    { \
        name = lua_tolstring(L, -2, &len); \
        lua_getfield(L, -1, "odds"); \
        odds = lua_tointeger(L, -1); \
        lua_pop(L, 2); \
        printf("%16.*s(%i%%)\t", len, name, odds); \
    } }
static int GetSkillList(lua_State * L)
{
    const char * name;
    int len;
    int odds;

    lua_getglobal(L, "SKILLS");
    for (lua_pushnil(L);;)
    {
        PRINT_SKILL(); PRINT_SKILL(); PRINT_SKILL(); PRINT_SKILL();
        printf("\n");
    }
    printf("\n");
    return 0;
}

typedef struct
{
    char nick[16];
    char name[16];
    char sex;
    char age;
    char ocpt[16];
    char skil[16];
} PlayerInfo;

static void printattrtable(AttrTable * t, int l)
{
    int i;
    AttrTable * p;

    printf("====================================== 属 === 性 === 表 ============================================\n"
           "||   ||力量(STR)|体质(CON)|体型(SIZ)|敏捷(DEX)||外貌(APP)|智力(INT)|意志(POW)|教育(EDU)|幸运(LUCK)||\n");
    for (i = 0; i < l; i++)
    {
        p = &(atable[i]);
        printf("||------------------------------------------------------------------------------------------------||\n"
               "|| %i || %7i | %7i | %7i | %7i || %7i | %7i | %7i | %7i |  %7i ||\n",
                i + 1, p->STR, p->CON, p->SIZ, p->DEX, p->APP, p->INT, p->POW, p->EDU, p->LUCK);
    }
    printf("====================================================================================================\n");
}

static int HandleConsole(lua_State * L)
{
    PlayerInfo info;
    AttrTable * atable;
    AttrTable * attr;
    int len;
    int res;

    atable = NULL;
    attr = NULL;
    try
    {
        printf("请输入角色姓名(PC): ");                             scanf("%s", &(info.name));
        printf("请选择角色性别(Sex):\t(1) 男性\t(2) 女性\t");       scanf("%hhi", &(info.sex));
        printf("请输入角色年龄(Age): ");                            scanf("%hhi", &(info.age));
        exit(0);
        /////////////////////////////////////////////////////////////////////////////////////////////
        len = GetAttrTable(L, &atable);
    choose_attr:
        printattrtable(atable, len);
        printf("请从上面的随机属性中任选一个并输入序号: ");         scanf("%i", &res);
        ChooseAttrTable(L, res);
        /////////////////////////////////////////////////////////////////////////////////////////////
    present_attr:
        printf("以下是您的角色属性:\n");
        printattrtable(&(atable[res]), 1);
        printf("以下是您的职业技能点数、兴趣技能点数、生命值、魔法值、理智值:\n");
        printf("\n");
        printf("请输入 Y(es) 确认您的选择，输入 N(o) 返回选择: ");  scanf("%c", &res);
        switch(res)
        {
            case 'Y':case 'y':
                { break; }
            case 'N':case 'n':
                { goto choose_attr; }
            default:
                { goto present_attr; }
        }
        /////////////////////////////////////////////////////////////////////////////////////////////
        printf("====================================== 职 === 业 === 表 ============================================\n");
        GetOccupationList(L);
        printf("====================================================================================================\n");
        printf("请从上面的职业列表中任选一个并输入名称: ");         scanf("%s", &(info.ocpt));
        /////////////////////////////////////////////////////////////////////////////////////////////
        printf("====================================== 技 === 能 === 表 ============================================\n");
        GetSkillList(L);
        printf("====================================================================================================\n");
        printf("请从上面的技能列表中任选一个并输入名称: ");         scanf("%s", &(info.skil));
        /////////////////////////////////////////////////////////////////////////////////////////////
        if (atable)
        {
            free(atable);
            atable = NULL;
        }
    }
    catch (int err)
    {
        if (atable)
        {
            free(atable);
            atable = NULL;
        }
        return err;
    }

    return 0;
}
*/

