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

#include "Dice.h"

#ifdef DEBUG
    #define DIR_LUA "data/scripts/"
#else
    #define DIR_LUA "../data/scripts/"
#endif

#define SEPARATOR '/'
#define FS_DEPTH 1024
#define MAIN_SCRIPT (DIR_LUA "main.lua")

using namespace std;

static int LoadLuaScripts(lua_State *);
static int RunMainScript(lua_State *);

// current release: Lua 5.3.4
int
main(int count, char ** argv)
{
    char path[PATH_MAX];
    lua_State * L;

    getcwd(path, PATH_MAX);
    printf("Current working directory: %s\n", path);
    // open Lua
    L = luaL_newstate();
    if (L == NULL)
    {
        printf("%s cannot create state: not enough memory", argv[0]);
        return EXIT_FAILURE;
    }
    luaL_checkversion(L);
    luaL_openlibs(L);
    LoadLuaScripts(L);
    // register C functions
    lua_register(L, "Dice", Roll);

    // run 'data/scripts/main.lua'
    RunMainScript(L);

    // close Lua
    lua_close(L);

    return EXIT_SUCCESS;
}

static int filterLuaFile(const struct dirent *ent)
{
    unsigned char type;
    char * name;
    char * ext;
    size_t len;

    type = ent->d_type;
    if (type == DT_DIR)
        return 1;
    else if (type != DT_REG)
        return 0;
    name = (char *) ent->d_name;
    len = strlen(name);
    ext = name + len - 3;
    return strcoll(ext, "lua") == 0;
}

static int join(char * dst, char * dir, char * ent)
{
    size_t len;

    memset(dst, 0, PATH_MAX);
    len = strlen(dir);
    strcpy(dst, dir);
    if (dir[len - 1] != SEPARATOR)
        dst[len++] = SEPARATOR;
    strcpy(dst + len, ent);

    return len;
}

static int LoadLuaScripts(lua_State * L)
{
    int count, res;
    FILE * file;
    int depth;
    char dirs[FS_DEPTH][PATH_MAX];
    char dirpath[PATH_MAX];
    struct dirent ** namelist;
    unsigned char d_type;
    char * d_name;
    char path[PATH_MAX];

    strcpy(dirs[0], DIR_LUA);
    depth = 1;
    while (depth--)
    {
        printf("====================================\n");
        strcpy(dirpath, dirs[depth]);
        namelist = NULL;
        count = scandir(dirpath, &namelist, filterLuaFile, alphasort);
        if (count < 0)
        {
            printf("Fail to scan dir: %s\n", dirpath);
            if (namelist)
            {
                printf("Dispose 'namelist'\n");
                free(namelist);
                namelist = NULL;
            }
            continue;
        }
        printf("Traverse directory '%s'\n", dirpath);
        printf("------------------------------------\n");
        while (count--)
        {
            d_type = namelist[count]->d_type;
            d_name = namelist[count]->d_name;
            // skip '.' and '..'
            if (d_name[0] == '.')
                continue;
            join(path, dirpath, d_name);
            // direcotry
            if (d_type == DT_DIR)
            {
                printf("Queue directory '%s'...\n", path);
                strcpy(dirs[depth++], path);
            }
            // file
            else if (d_type == DT_REG)
            {
                res = luaL_loadfile(L, path);
                printf("Try to load Lua file '%s'\t%s\n", path,
                        res == LUA_OK ? "" : "[FAIL!]");
                if (res != LUA_OK)
                {
                    // print lua error
                    switch (res)
                    {
                        case LUA_ERRFILE:
                            fprintf(stderr, "Lua: Fail to open file!");
                            break;
                        case LUA_ERRSYNTAX:
                            fprintf(stderr, "Lua: syntax error during precompilation!");
                            break;
                        case LUA_ERRMEM:
                            fprintf(stderr, "Lua: out of memory!");
                            break;
                        case LUA_ERRGCMM:
                            fprintf(stderr, "Lua: gc error!");
                            break;
                    }
                }
                else
                {
                    // pop lua chunk; clean up stack
                    lua_pop(L, 1);
                }
            }
            // other
            else
                printf("Unrecognizeable entry!\n");
            // free current entry
            free(namelist[count]);
        }
        // free entry list
        free(namelist);
        namelist = NULL;
    }
    printf("====================================\n");

    return EXIT_SUCCESS;
}

static int RunMainScript(lua_State *)
{
    return EXIT_SUCCESS;
}
