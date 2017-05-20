#ifndef THESIM_H
#define THESIM_H
#endif

#include <stack>
#include <chrono>
#include <random>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "TheNet.h"

class TheSim
{
public:
    TheSim();
    ~TheSim();
    lua_State *GetLVM();
    int RunScript(const char *);
    int PushDebugger();

    static TheSim * GetDefault();
    static void SetDefault(TheSim *);

    int RandomInt(int);
private:
    lua_State *L;
    std::default_random_engine * randgen;
    static TheSim * sim;
};

class TheNet
{
public:
    TheNet(lua_State *);
    ~TheNet();

    void            StartServer(int);
    void            StartClient(unsigned int, const char *, int);
    void            Send(const char *, int);
    void            Close();
private:
    Server *        server;
    Client *        client;
    ClientMap       handlers;
};

// Dice.cpp
extern int Roll(lua_State *);
// TheSim.cpp
extern int luaS_makemeta(lua_State *, const luaL_Reg *, const char *);
//--{
const static char LUA_STATUS[][16] =
{
    "",
    "LUA_OK",
    "LUA_ERRRUN",
    "LUA_ERRSYNTAX",
    "LUA_ERRMEM",
    "LUA_ERRGCMM",
    "LUA_ERRERR"
};
#define luaS_getstring(status) ( (status > 0 && status < sizeof(LUA_STATUS)) ? LUA_STATUS[status] : "???" )
//--}

// Pop all items on stack
#define luaS_pop(L) { lua_pop(L, lua_gettop(L)); }
#define ThrowLuaError(s) { \
        luaS_pop(L); \
        throw luaL_error(L, s); }
#define luaS_addmethod(L, name, func) { \
        lua_pushcfunction(L, func); \
        lua_setfield(L, -2, name); \
    }
