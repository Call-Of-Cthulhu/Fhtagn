#include "LuaClass.h"

LuaClass::LuaClass(const char *name)
{
    this->name = name;
}

LuaClass::~LuaClass()
{
    this->name = NULL;
    functions.clear();
}

int LuaClass::AddFunction(const char * name, lua_CFunction func)
{
    if (this->name == NULL)
        return 1;
    this->functions[name] = func;
    return 0;
}

int LuaClass::RegisterFunctions(lua_State * L)
{
    size_t count;
    std::map<const char *, lua_CFunction>::iterator it;

    if (this->name == NULL)
        return 1;
    count = this->functions.size();
    // create a new table and push it onto the stack
    lua_createtable(L, 0, count);
    for (it = this->functions.begin();
            it != this->functions.end();
            ++it)
    {
        // function name
        lua_pushstring(L, it->first);
        // function pointer
        lua_pushcfunction(L, it->second);
        // map name and function in the table:
        //      Class.name = func
        lua_rawset(L, -3);
    }
    lua_setglobal(L, this->name);
    this->name = (const char *) NULL;
    return 0;
}
