#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <csignal>
#include <cstring>
#include <thread>

#include "Error.hpp"
#include "TheSim.h"
#include "Entity.h"
#include "TheNet.h"

#define BACKLOG     8
#define MAIN_SCRIPT "data/Mythos/data/scripts/main.lua"

TheSim * TheSim::sim = (TheSim *) NULL;

static int PrintStack(lua_State *);

// @see lua.c
static int _msghandler(lua_State * L)
{
    const char * msg = lua_tostring(L, 1);
    if (!msg)
    {
        if (luaL_callmeta(L, 1, "__tostring")
                && lua_type(L, -1) == LUA_TSTRING)
            return 1; // return 1 lua string
        else
            msg = lua_pushfstring(L, "(error object is a %s value)",
                    luaL_typename(L, 1));
    }
    luaL_traceback(L, L, msg, 1);
    return 1; // return 1 lua string
}

static inline int _pushdebugger(lua_State * L)
{
    int top;

    lua_pushcfunction(L, _msghandler);
    top = lua_gettop(L);
    return top;
}

//--{ParseSkillList
static int ParseInteger(const char * s, int l)
{
    int i, t;

    if (s == NULL || l == 0) return 1;
    for (i = t = 0; i < l && s[i] >= '0' && s[i] <= '9'; i++)
        t = t * 10 + (s[i] - '0');
    return t;
}
// assert
#define CheckState(exp) {if (!(exp)) { \
        ThrowLuaError("Invalid State: " #exp ); }}
#define checkstack(s) { printf("    Stack depth (%s): %d\n", s, lua_gettop(L)); }
// peek next char
#define next(ptr) (*(ptr + 1))
// clean up
#define cleanup() { \
        skill = major = count = NULL; \
        lskill = lmajor = lcount = 0; }
#if 0 //--(
    // push a table: { skill = skill, major = major }
    #define pushskill() { \
            if (major) \
            { \
                printf("%.*s(%.*s)", lskill, skill, (lmajor), (major)); \
            } \
            else \
            { \
                printf("%.*s", lskill, skill); \
            } \
        }
    // push a integer: count
    #define pushcount() { \
            printf("%d\n", ParseInteger(count, lcount)); \
        }
    // create a skill list
    #define NewList() { \
            printf("[{"); \
            idx = 0; \
        }
    // append skill to the list
    #define AddSkill() { \
            if (idx++) printf(","); \
            pushskill(); \
            cleanup(); \
        }
    // set table: table[skill] = count
    #define PutSkillAndCount() { \
            printf("["); \
            pushskill(); \
            printf("] = "); \
            pushcount(); \
            cleanup(); \
        }
    // set table: table[list] = count
    #define PutListAndCount() { \
            printf("}] = "); \
            pushcount(); \
            cleanup(); \
        }
#else               //--)(
    // push a table: { skill = skill, major = major }
    #define pushskill() { \
            lua_newtable(L); \
            lua_pushliteral(L, "Skill"); \
            lua_setfield(L, -2, "__name"); \
            CheckState(skill != NULL && lskill > 0); \
            lua_pushlstring(L, skill, lskill); \
            lua_setfield(L, -2, "skill"); \
            if (major) { \
                lua_pushlstring(L, major, lmajor); \
                lua_setfield(L, -2, "major"); \
            } \
        }
    // push a integer: count
    #define pushcount() { \
            lua_pushinteger(L, ParseInteger(count, lcount)); \
        }
    // create a skill list
    #define NewList() { \
            lua_newtable(L); \
            lua_pushliteral(L, "Skill-List"); \
            lua_setfield(L, -2, "__name"); \
            idx = 0; \
        }
    // append skill to the list
    #define AddSkill() { \
            pushskill(); \
            lua_rawseti(L, -2, ++idx); \
            cleanup(); \
        }
    // set table: table[skill] = count
    #define PutSkillAndCount() { \
            pushskill(); \
            pushcount(); \
            lua_rawset(L, -3); \
            cleanup(); \
        }
    // set table: table[list] = count
    #define PutListAndCount() { \
            pushcount(); \
            lua_rawset(L, -3); \
            cleanup(); \
        }
#endif              //--)
static int ParseSkillList(lua_State * L)
{ // <a>
    const char * s;
    size_t l;   // length
    char * p;   // iterator
    char * m;   // mark
    // States
    char s1;    // State [ ]
    char s2;    // State ( )
    const char * sav;
    int len;
    const char * skill;
    const char * major;
    const char * count;
    int lskill, lmajor, lcount;
    // index for appending skills into skill list
    int idx;

    const int top = lua_gettop(L);
    //printf("C function '%s' is invoked ..\n", __func__);
    //PrintStack(L);
    luaL_argcheck(L, top == 1, top, "invalid argument count");
    // input
    s = lua_tostring(L, 1);
    luaL_argcheck(L, s, 1, "invalid argument type");
    // Clean up stack
    lua_pop(L, 1);
    l = strlen(s);
    // init
    s1 = s2 = 0;
    skill = major = count = (const char *) NULL;
    lskill = lmajor = lcount = 0;
    // create a map: { [skill] = count }
    lua_newtable(L);
    lua_pushliteral(L, "Skill-Map");
    lua_setfield(L, -2, "__name");
    // start parsing
    p = (char *) s;
    CheckState(next(p) >= 'A' && next(p) <= 'Z' || next(p) == '*' || next(p) == '[');
    //
    for (; ; p++)
    {
        switch (*p)
        {
            ///////////////////////////////////////////////////////
            //      Attend to Lua stack
            ///////////////////////////////////////////////////////
            case ',':
                CheckState(next(p) >= 'A' && next(p) <= 'Z' || next(p) == '*' || next(p) == '[');
                // don't break
            case '\0':
            {
                s2 = 0;
                switch (s1)
                {
                    case 0:     // before '['
                    {
                        PutSkillAndCount();
                        break;
                    }
                    case 1:     // between '[' and ']'
                    {
                        CheckState(*p != '\0');
                        AddSkill();
                        break;
                    }
                    case 4:     // after '|'
                        // Add the last skill
                        AddSkill();
                        // don't break
                    case 2:     // after ']'
                    {
                        s1 = 0;
                        PutListAndCount();
                        break;
                    }
                }
                break;
            }
            case '|':
            {
                CheckState(s1 == 0 || s1 == 4);
                CheckState(next(p) >= 'A' && next(p) <= 'Z');
                s2 = 0;
                switch (s1)    // first encounter with '|'
                {
                    case 0:
                    {
                        s1 = 4;
                        NewList();
                        break;
                    }
                    case 4:
                    { break; }
                    default:
                    {
                        ThrowLuaError("Invalid state!");
                    }
                }
                AddSkill();
                break;
            }
            case '[':
            {
                CheckState(s1 == 0);
                CheckState(s2 == 0);
                CheckState(next(p) >= 'A' && next(p) <= 'Z');
                s1 = 1;
                NewList();
                break;
            }
            case ']':
            {
                CheckState(s1 == 1);
                CheckState(next(p) == '(');
                s1 = 2;
                s2 = 0;
                // put last skill into skill list
                AddSkill();
                break;
            }
            ///////////////////////////////////////////////////////
            case '(':
            {
                CheckState(s2 == 0);
                CheckState(next(p) >= 'A' && next(p) <= 'Z' || next(p) >= '0' && next(p) <= '9');
                s2 = 1;
                break;
            }
            case ')':
            {
                CheckState(s2 == 1);
                CheckState(next(p) == ',' || next(p) == '|' || next(p) == ']' || next(p) == '\0');
                s2 = 2;
                break;
            }
            ///////////////////////////////////////////////////////
            //      Make String 'skill', 'major', 'count'
            ///////////////////////////////////////////////////////
            case '*':
            {
                CheckState(next(p) == '(');
                skill = "*";    lskill = 1;
                major = NULL;   lmajor = 0;
                break;
            }
            case 'A':case 'B':case 'C':case 'D':case 'E':
            case 'F':case 'G':case 'H':case 'I':case 'J':
            case 'K':case 'L':case 'M':case 'N':case 'O':
            case 'P':case 'Q':case 'R':case 'S':case 'T':
            case 'U':case 'V':case 'W':case 'X':case 'Y':
            case 'Z':
            {
                sav = p;
                while (next(p) >= 'A'
                        && next(p) <= 'Z'
                        || next(p) == '_')
                    ++p;
                len = p + 1 - sav;
                switch (s2)
                {
                    case 0:     // before '('
                    {
                        CheckState(next(p) == ',' || next(p) == '\0' || next(p) == '|' || next(p) == ']' || next(p) == '(');
                        skill = sav;
                        lskill = len;
                        break;
                    }
                    case 1:     // between '(' and ')'
                    {
                        CheckState(next(p) == ')');
                        major = sav;
                        lmajor = len;
                        break;
                    }
                }
                break;
            }
            case '0':case '1':case '2':case '3':case '4':
            case '5':case '6':case '7':case '8':case '9':
            {
                CheckState(s2 == 1);
                sav = p;
                while (next(p) >= '0'
                        && next(p) <= '9')
                    ++p;
                CheckState(next(p) == ')');
                len = p + 1 - sav;
                count = sav;
                lcount = len;
                break;
            }
            default:
            {
                ThrowLuaError("Invalid input!");
            }
        }
        // break the loop
        if (*p == '\0')
            break;
        // clean up, prevent lortering
        sav = NULL;
        len = 0;
    }

    return 1; // number of results
} // <a>
//--}

////////////////////////////////////////////////////////
// TheSim methods
////////////////////////////////////////////////////////

// TheSim:CreateEntity()
static int _CreateEntity(lua_State * L)
{
    const int n = lua_gettop(L);
    Entity *ent;

    luaL_argcheck(L, n == 1, n, "invalid argument count");
    ent = new Entity(L);
    return 1;
}

static const luaL_Reg REG_THESIM[] =
{
    { "CreateEntity", _CreateEntity },
    { NULL, NULL }
};

static inline void print_short_string(lua_State * L, char * b, int i)
{
    const char *sVal;
    size_t      sLen;

    sVal = lua_tolstring(L, i, &sLen);
    if (sVal == NULL)
    {
        b[0] = '\0';
        return;
    }
    if (sLen > 12)
    {
        sprintf(b, "%.*s", 7, sVal);
        sprintf(b + 7, "..");
        sprintf(b + 9, "%.*s", 3, sVal + sLen - 3);
        b[12] = '\0';
    }
    else
    {
        sprintf(b, "%s", sVal);
        b[sLen] = '\0';
    }
}
static int PrintStack(lua_State * L)
{
    const int   top = lua_gettop(L);
    int         i;
    int         t;
    const char *n;
    char        b[32];
    int         nbits;
    lua_Number  fVal;
    int         bVal;

    // 24 columns
    printf("============================\n"
           "| Stack size: %12i |\n",
           top);
    if (top > 0)
    {
        printf("============================\n"
               "| Index | Stack Entry Type |\n");
        for (i = 1; i <= top; i++)
        {
            t = lua_type(L, i);
            switch (t)
            {
                case LUA_TNIL:
                    n = "nil";
                    b[0] = '\0';
                    break;
                case LUA_TNUMBER:
                    n = "num";
                    fVal = lua_tonumber(L, i);
                    snprintf(b, sizeof(b), "%.3g", fVal);
                    break;
                case LUA_TBOOLEAN:
                    n = "bul";
                    bVal = lua_toboolean(L, i);
                    if (bVal)
                        snprintf(b, 5, "true");
                    else
                        snprintf(b, 6, "false");
                    break;
                case LUA_TSTRING:
                    n = "str";
                    print_short_string(L, b, i);
                    break;
                case LUA_TTABLE:
                case LUA_TTHREAD:
                case LUA_TFUNCTION:
                case LUA_TUSERDATA:
                case LUA_TLIGHTUSERDATA:
                    lua_getglobal(L, "tostring");
                    lua_pushvalue(L, i);
                    if (lua_pcall(L, 1, 1, 0) == LUA_OK)
                    {
                        n = NULL;
                        print_short_string(L, b, -1);
                    }
                    else
                    {
                        n = lua_typename(L, t);
                        b[0] = '\0';
                    }
                    break;
                default:
                    n = lua_typename(L, t);
                    return luaL_error(L, "Unknown Lua type %i:%s", t, n);
            }
            if (n != NULL)
                printf("----------------------------\n"
                        "| %5i | %s %12s |\n",
                        i, n, b);
            else
                printf("----------------------------\n"
                        "| %5i | %-16s |\n",
                        i, b);
        }
    }
    printf("============================\n");

    return 0;
}

static void SIGINT_HDL(int sig)
{
    TheSim * sim;

    sim = TheSim::GetDefault();
    if (sim)
    {
        delete sim;
        TheSim::SetDefault(NULL);
    }
    exit(0);
}

static void SIGABRT_HDL(int sig)
{
    TheSim * sim = TheSim::GetDefault();
    lua_State * L = sim->GetLVM();
    PrintStack(L);
}

// constructor
TheSim::TheSim()
{
    int top;
    TheNet * net;
    unsigned seed;

#ifdef DEBUG
    printf("Start initializing TheSim...\n");
    if (TheSim::sim)
        throw new Error("TheSim is already initialized!");
#endif
    // Open Lua
    L = luaL_newstate();
    if (L == NULL)
        throw new Error("Fail to create state: not enough memory!");
    luaL_checkversion(L);
    luaL_openlibs(L);
    TheSim::sim = this;

    signal(SIGABRT, SIGABRT_HDL);
    signal(SIGINT,  SIGINT_HDL);

    ////////////////////////////////////////////////////
    // _G.ParseSkillList
    lua_register(L, "ParseSkillList", ParseSkillList);
    // _G.Dice
    lua_register(L, "Dice", Roll);
    // _G.PrintStack
    lua_register(L, "PrintStack", PrintStack);

    luaS_makemeta(L, REG_THESIM, "TheSim");
    MakeEntityMetaTable(L);
    ////////////////////////////////////////////////////
    // Create 'TheSim'
    lua_pushlightuserdata(L, this); // TheSim
    luaL_setmetatable(L, "TheSim");
    lua_setglobal(L, "TheSim");
    ////////////////////////////////////////////////////
    // Create 'TheNet'
    ////////////////////////////////////////////////////
    //net = new TheNet(L);
#ifdef DEBUG
    printf("TheSim initialization done.\n");
    //PrintStack(L);
#endif
    seed = std::chrono::system_clock::now().time_since_epoch().count();
    randgen = new std::default_random_engine(seed);
    ////////////////////////////////////////////////////
    // run 'data/scripts/main.lua'
    ////////////////////////////////////////////////////
    RunScript(MAIN_SCRIPT);
}

// deconstructor
TheSim::~TheSim()
{
    Entity * ent;
    TheNet * net;

#ifdef DEBUG
    printf("Start recycling TheSim ...\n");
#endif
    if (randgen)
    {
        delete randgen;
        randgen = NULL;
    }
    /////////////////////////////////////
    // Dispose all entities
    /////////////////////////////////////
    if (lua_getglobal(L, "Ents") == LUA_TTABLE)
    {
#ifdef DEBUG
        printf("Start recycling global 'Ents' ...\n");
#endif
        // for uuid, scr in pairs(Ents) do
        for (lua_pushnil(L), ent = NULL;
                lua_next(L, 1) != 0;)
        {
            //PrintStack(L);
            assert(lua_type(L, -2) == LUA_TSTRING && lua_type(L, -1) == LUA_TTABLE);
            lua_getfield(L, -1, "entity"); // push scr.entity
            ent = (Entity *) luaL_testudata(L, -1, "CEntity"); // @
            if (ent)
            {
                delete ent;
                ent = NULL;
            }
            lua_pop(L, 2); // pop scr.entity; pop scr
        }
#ifdef DEBUG
        printf("All entries in global 'Ents' have been recycled.\n");
#endif
        //PrintStack(L);
        assert(lua_gettop(L) == 1 && lua_type(L, 1) == LUA_TTABLE);
        lua_pop(L, lua_gettop(L));
    }
    {
        lua_getglobal(L, "TheNet");
        net = (TheNet *) luaL_testudata(L, -1, "TheNet");
        if (net)
        {
#ifdef DEBUG
            printf("TheNet is recycled.\n");
#endif
            delete net;
            net = NULL;
        }
        lua_pop(L, 1);
    }
    /////////////////////////////////////
    // Close Lua
    /////////////////////////////////////
    lua_close(L);
    TheSim::sim = NULL;
#ifdef DEBUG
    printf("LVM is closed.\n");
#endif
}

lua_State *TheSim::GetLVM()
{
    return L;
}

int TheSim::RunScript(const char * path)
{
    int top;
    int res;
    int msgh;

#ifdef DEBUG
    printf("Running script: %s ...\n", path);
#endif
    top = lua_gettop(L);
    msgh = PushDebugger(); // insert message handler
    res = luaL_loadfile(L, path);
    if (res != LUA_OK)
    {
        throw new Error("Lua (%i:%s): Fail to load file! {\n%s\n}",
                res, luaS_getstring(res), lua_tostring(L, -1));
    }

    res = lua_pcall(L, 0, LUA_MULTRET, msgh);

    if (res != LUA_OK)
    {
        throw new Error("Lua (%i:%s): Fail to execute file! {\n%s\n}",
                res, luaS_getstring(res), lua_tostring(L, -1));
    }
    lua_remove(L, msgh); // remove message handler
    assert(top == lua_gettop(L)); // this function must be balanced !!!
    return EXIT_SUCCESS; // success
}

// ALWAYS remember to pop the message handler when you finish
int TheSim::PushDebugger()
{
    return _pushdebugger(L);
}

static inline int getRegLen(const luaL_Reg * reglist)
{
    int i;

    i = 0;
    while (reglist[i].name) ++i;
    return i;
}
#if 0
static int my_tostring(lua_State * L)
{
    int res;
    size_t len;
    char buf[4096];
    char * ptr;
    const char * str;

    switch (lua_type(L, 1))
    {
        case LUA_TNIL:
        {
            lua_pushliteral(L, "nil");
            return 1;
        }
        case LUA_TLIGHTUSERDATA:case LUA_TUSERDATA:
            lua_pushcfunction(L, my_tostring);
            res = lua_getmetatable(L, 1);
            if (res)
            {
                lua_call(L, 1, 1);
                return 1;
            }
            lua_remove(L, 2);
        case LUA_TFUNCTION:case LUA_TTHREAD:
        case LUA_TNUMBER:case LUA_TBOOLEAN:case LUA_TSTRING:
        {
            lua_getglobal(L, "tostring");
            lua_insert(L, 1);
            lua_call(L, 1, 1);
            return 1;
        }
        case LUA_TTABLE:
        {
            memset(buf, 0, sizeof(buf));
            ptr = (char *) buf;
            *ptr++ = '{';
            for (lua_pushnil(L); lua_next(L, 1) != 0;)
            {
                strcpy(ptr, "\r\t[");
                ptr += 3;
                // key
                lua_pushcfunction(L, my_tostring);
                lua_pushvalue(L, 2);
                lua_call(L, 1, 1);
                str = lua_tolstring(L, -1, &len);
                strncpy(ptr, str, len);
                ptr += len;
                // separator
                strcpy(ptr, "] = (");
                ptr += 5;
                // value
                lua_pushcfunction(L, my_tostring);
                lua_pushvalue(L, 3);
                lua_call(L, 1, 1);
                str = lua_tolstring(L, -1, &len);
                strncpy(ptr, str, len);
                ptr += len;
                // separator
                strcpy(ptr, "),\r");
                ptr += 3;
                // clean up stack
                lua_pop(L, 4);
            }
            strcpy(ptr, "\r}");
            ptr += 2;
            lua_pushlstring(L, buf, (int) (ptr - buf));
            return 1;
        }
    }
    return luaL_error(L, "invalid value type (%s)",
            luaL_typename(L, -1));
}
#endif
// @see lauxlib.c luaL_newmetatable(lua_State *, const char *)
extern int luaS_makemeta(lua_State * L,
        const luaL_Reg * reglist, const char * name)
{
    const int regsize = getRegLen(reglist);
#ifdef DEBUG
    const int top = lua_gettop(L);
#endif
    if (luaL_getmetatable(L, name) == LUA_TNIL) // name is still available
    {
        lua_createtable(L, 0, regsize + 2);
        luaL_setfuncs(L, reglist, 0); // metatable.<k> = <v>
        lua_pushstring(L, name);
        lua_setfield(L, -2, "__name"); // metatable.__name = name
        lua_pushvalue(L, -1);
        lua_setfield(L, -2, "__index"); // metatable.__index = metatable
        //lua_pushcfunction(L, my_tostring);
        //lua_setfield(L, -2, "__tostring"); // metatable.__tostring = my_tostring
        lua_setfield(L, LUA_REGISTRYINDEX, name); // registry.name = metatable
#ifdef DEBUG
        printf("New metatable is created for '%s', method count: %i ...\n", name, regsize);
#endif
    }
    lua_pop(L, 1);
#ifdef DEBUG
    assert(top == lua_gettop(L)); // or stack is not balanced !
#endif
    return 1; // new metatable created
}

TheSim * TheSim::GetDefault()
{
    return sim;
}

void TheSim::SetDefault(TheSim * sim)
{
    TheSim::sim = sim;
}

int TheSim::RandomInt(int dice)
{
    if (!randgen)
        throw new Error("Field 'randgen' is null");
    std::uniform_int_distribution<int> dist(1, dice);
    return dist(*randgen);
}

///////////////////////////////////////////////////////////////
// { TheNet
///////////////////////////////////////////////////////////////
// TheNet:StartServer(port)
static int _StartServer(lua_State * L)
{
    TheNet * net;
    lua_Integer lPort;
    int status;
    int port;

    net = (TheNet *) luaL_checkudata(L, 1, "TheNet");
    lPort = lua_tointegerx(L, 2, &status);
    port = (int) (0xffff & lPort);
    return 0;
}

static const luaL_Reg REG_THENET[] =
{
    // TheNet:GetServerName()
    // TheNet:GetServerMaxPlayers()
    //
    // TheNet:GetLocalUserName()
    // TheNet:GetUserID()
    //
    // TheNet:GetIsServer()
    // TheNet:GetIsClient()
    //
    // TheNet:DiceRoll(sides, dice)
    //
    // TheNet:GetClientTable()
    //
    // TheNet:GetPVPEnabled()
    //
    // TheNet:StartServer()
    // TheNet:StartClient(DEFAULT_JOIN_IP)
    // TheNet:Disconnect(boolean)
    //
    // TheNet:SendRPCToServer(dest, code, ...)
    // TheNet:CallRPC(fn, sender, data)
    //
    // TheNet:ViewNetProfile(server_group)
    { "StartServer", _StartServer },
    { NULL, NULL }
};

static inline int getdefaultport(lua_State * L)
{
    int             status;
    lua_Integer     port;

    status = lua_getglobal(L, "DEFAULT_SERVER_PORT");
    if (status != LUA_TNUMBER)
        return luaL_error(L, "invalid value type %s!", luaL_typename(L, -1)); // maybe lua value hasn't been initiialized
    port = lua_tointegerx(L, -1, &status);
    if (!status)
        return luaL_error(L, "'DEFAULT_SERVER_PORT' is type %s!", luaL_typename(L, -1)); // expect integer
    return (int) (port & 0xffff);
}

#define NetAPI TheNet::

NetAPI TheNet(lua_State * L)
{
    int res;
    int port;

    luaS_makemeta(L, REG_THENET, "TheNet");
    // Create 'TheNet'
    lua_pushlightuserdata(L, this);
    luaL_setmetatable(L, "TheNet");
    lua_setglobal(L, "TheNet");

    server = NULL;
    client = NULL;
}

NetAPI ~TheNet()
{
    if (server)
    {
        delete server;
        server = NULL;
    }
    if (client)
    {
        delete client;
        client = NULL;
    }
}

void NetAPI StartServer(int port)
{
    if (server == NULL)
    {
        server = new Server{port};
        if (server == NULL)
            throw new Error("Fail to allocate memory for server");
    }
    else
    {
        server->Close();
    }
    server->Start();
}

void NetAPI StartClient(unsigned int interval, const char * addr, int port)
{
    if (client == NULL)
    {
        client = new Client;
        if (client == NULL)
            throw new Error("Fail to allocate memory for client");
        client->Connect(addr, port);
    }
    else
    {
        client->Close();
    }
    client->Start(interval);
}

void NetAPI Send(const char * msg, int len)
{
    if (client == NULL)
    {
        throw new Error("Fail to send message: client is NULL");
    }
    client->Send(msg, len);
}

void NetAPI Close()
{
    if (server)
    {
        server->Close();
    }
    if (client)
    {
        client->Close();
    }
}

// }



