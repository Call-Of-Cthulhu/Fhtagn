#ifndef ENTITY_H
#define ENTITY_H

#include "lua.h"

//"Requires libuuid!"
// https://linux.die.net/man/3/libuuid
//#include <uuid/uuid.h>
// a replacebo for <uuid/uuid.h>
typedef long long GUID;

class Entity
{
public:
    GUID GetGUID(lua_State *);
};

#endif /* ENTITY_H */
