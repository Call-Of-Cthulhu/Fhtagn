#ifndef ENTITY_H
#define ENTITY_H

#include <map>

#include <uuid/uuid.h>

typedef std::map<const char *, bool> TagSet;

class Entity
{
public:
    Entity(lua_State *);
    void GetUUID(uuid_t);
    TagSet * GetTags();
private:
    uuid_t id;
    TagSet tags;
};

extern void MakeEntityMetaTable(lua_State *);

#endif /* ENTITY_H */
