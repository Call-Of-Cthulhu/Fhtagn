#ifndef THESIM_H
#define THESIM_H

#include "lua.h"

#include "Entity.h"

class TheSim
{
public:
   Entity * CreateEntity(lua_State *);
};

#endif /* THESIM_H */
