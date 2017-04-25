#ifndef LUACLASS_H
#define LUACLASS_H

#include <map>

#include "lua.h"

class LuaClass
{
public:
    LuaClass(const char *);
    ~LuaClass();
    int AddFunction(const char *, lua_CFunction);
    int RegisterFunctions(lua_State *);
private:
    const char * name;
    std::map<const char *, lua_CFunction> functions;
};

#endif /* LUACLASS_H */
