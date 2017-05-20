#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "TheSim.h"
#include "Entity.h"

#define MYTYPE_VAL          "CEntity"
#define UUID_UNPARSE_LENGTH 64

Entity::Entity(lua_State * L)
{
    int top;

    uuid_clear(id);
    uuid_generate(id);
    lua_pushlightuserdata(L, this);
    luaL_setmetatable(L, MYTYPE_VAL);
}

void Entity::GetUUID(uuid_t out)
{
    uuid_copy(out, id);
}

TagSet * Entity::GetTags()
{
    return &tags;
}
///////////////////////////////////////////////////////////////
// Entity:GetUUID()
static int _GetUUID(lua_State * L)
{
    const int n = lua_gettop(L);
    Entity * ent;
    uuid_t res;
    char str[UUID_UNPARSE_LENGTH];

    luaL_argcheck(L, n == 1, n, "invalid argument count");
    ent = (Entity *) lua_touserdata(L, 1);
    luaL_argcheck(L, ent, 1, "invalid argument type");
    ent->GetUUID(res);
    memset(str, 0, sizeof(str));
    uuid_unparse_lower(res, str);
    lua_pushstring(L, str);
    return 1;
}
// Entity:AddTag(s)
static int _AddTag(lua_State * L)
{
    const int n = lua_gettop(L);
    Entity * ent;
    const char * s;
    TagSet * set;

    luaL_argcheck(L, n == 2, n, "invalid argument count");
    ent = (Entity *) lua_touserdata(L, 1);
    luaL_argcheck(L, ent, 1, "invalid argument type");
    s = lua_tostring(L, 2);
    luaL_argcheck(L, s, 2, "invalid argument type");
    set = ent->GetTags();
    (*set)[s] = 1;
    return 0;
}
// Entity:RemoveTag(s)
static int _RemoveTag(lua_State * L)
{
    const int n = lua_gettop(L);
    Entity * ent;
    const char * s;
    TagSet * set;

    luaL_argcheck(L, n == 2, n, "invalid argument count");
    ent = (Entity *) lua_touserdata(L, 1);
    luaL_argcheck(L, ent, 1, "invalid argument type");
    s = lua_tostring(L, 2);
    luaL_argcheck(L, s, 2, "invalid argument type");
    set = ent->GetTags();
    set->erase(s);
    return 0;
}
// Entity:HasTag(s)
static int _HasTag(lua_State * L)
{
    const int n = lua_gettop(L);
    Entity * ent;
    const char * s;
    TagSet * set;

    luaL_argcheck(L, n == 2, n, "invalid argument count");
    ent = (Entity *) lua_touserdata(L, 1);
    luaL_argcheck(L, ent, 1, "invalid argument type");
    s = lua_tostring(L, 2);
    luaL_argcheck(L, s, 2, "invalid argument type");
    set = ent->GetTags();
    lua_pushboolean(L, (set->find(s) != set->end()));
    return 1;
}
// Place holder
static int _AddNone(lua_State * L)
{
    return 0;
}
///////////////////////////////////////////////////////////////
static const luaL_Reg REG_ENTITY[] =
{
    { "GetUUID", _GetUUID },
    { "AddTag", _AddTag },
    { "RemoveTag", _RemoveTag },
    { "HasTag", _HasTag },

    { "AddTransform", _AddNone },
    { "AddAnimState", _AddNone }, 
    { "AddSoundEmitter", _AddNone },
    { "AddDynamicShadow", _AddNone },
    { "AddMiniMapEntity", _AddNone },
    { "AddLight", _AddNone },
    { "AddLightWatcher", _AddNone },
    { "AddNetwork", _AddNone },

    { NULL, NULL }
};
// register metatable for Entity in TheSim
extern void MakeEntityMetaTable(lua_State * L)
{
    int top = lua_gettop(L);
    if (luaL_newmetatable(L, MYTYPE_VAL))
    {
        lua_pushvalue(L, -1); // copy metatable
        lua_setfield(L, -2, "__index"); // metatable.__index = metatable
        luaL_setfuncs(L, REG_ENTITY, 0); // Entity methods
        lua_setglobal(L, "Entity");
    }
    top = lua_gettop(L) - top;
    if (top > 0)
    {
#ifdef DEBUG
        printf("MakeEntityMetaTable: pop out %i frames.", top);
#endif
        lua_pop(L, top);
    }
}


