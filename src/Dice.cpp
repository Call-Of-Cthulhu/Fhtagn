/*
 * Author   : KaiserKatze
 * Date     : 2017-4-14
 * License  : GPLv3
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined __GXX_EXPERIMENTAL_CXX0X__
    #include <chrono>
    #include <random>
#else
    #if defined _WIN32          // Windows 32 or Windows 64
        #include <time.h>
    #elif defined __linux__     // Linux
        #include <sys/time.h>
    #else
        //_WIN64        Windows 64
        //__MINGW32__   Windows 32 by mingw
        //__CYGWIN__    Cygwin
        //__FreeBSD__   FreeBSD
        //__NetBSD__    NetBSD
        //__OpenBSD__   OpenBSD
        //__sun__       Sun OS
        //__MaxOSX__    MAC OS X
        //__unix__      unix
        #error "Unsupported platform, NO GUARANTY!"
    #endif
#endif

#include "Dice.h"

static int Roll0(const int count, const int dice)
{
#if USE_CPP11
    unsigned seed;

    seed = std::chrono::system_clock::now().time_since_epoch().count();
    std::default_random_engine generator(seed);
    std::uniform_int_distribution<int> distribution(1, dice);
    return distribution(generator);
#else
    int i, s;

    srand(time(NULL));
    s = count;
    for (i = 0; i < count; i++)
        // generate a random number from 0 to (dice - 1)
        s += (rand() % dice);
    return s;
#endif
}

/**
 * Dice(count, dice)
 */
int Roll(lua_State * L)
{
    int nargs;
    int count, dice, result;

    if (L == NULL)
        return -1;
    // number of arguments
    nargs   = lua_gettop(L);
    // remove abundant arguments
    while (nargs > 2)
    {
        lua_pop(L, 1);
        --nargs;
    }
    // validate argument type
    if (!lua_isinteger(L, 1) || !lua_isinteger(L, 2))
    {
        lua_pushliteral(L, "Invalid argument");
        lua_error(L);
        return -1;
    }
    dice    = (int) lua_tointeger(L, 2);
    count   = (int) lua_tointeger(L, 1);
    result  = Roll0(count, dice);
#ifdef DEBUG
    printf("%dd%d = %d\n", count, dice, result);
#endif
    // push result
    lua_pushinteger(L, result);
    // return number of results
    return 1;
}
