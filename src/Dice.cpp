/*
 * Author   : KaiserKatze
 * Date     : 2017-4-14
 * License  : GPLv3
 */
//--{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <stack>
/*
#if 0
    #if defined _WIN32          // Windows 32 or Windows 64
    #elif defined __linux__     // Linux
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
*/

#include "TheSim.h"
#include "Error.hpp"
//--}

//                       Index :   0  1  2  3  4  5  6  7  8  9
//                      Symbol :   (  )  *  +     -     /  D   
static const char PRECEDENCE[] = { 0, 4, 2, 1, 0, 1, 0, 2, 3, 0 };

static int Roll0(const int count, const int dice)
{
    int i, s;
    
    s = 0;
    for (i = 0; i < count; i++)
        s += TheSim::GetDefault()->RandomInt(dice);
    return s;
}

class ArithmeticStack
{
public:
    int Parse(lua_State *, const char *, size_t);
    int ParseInt(const char *, size_t);
private:
    typedef std::stack<int> NumberStack;
    typedef std::stack<char> PriorityStack;

    NumberStack stn;
    PriorityStack stp;

    int IsDigit(const char);
protected:
    int IsWhitespace(const char);
    int IsOperator(const char);
    int Compare(char c);
    void Calc();
};

static int Roll1(lua_State * L, const char * s, int l)
{
    ArithmeticStack stack;
    char * p, * q;
    int i, n;
    int res;

    for (p = (char *) s, q = (char *) (s + l);
            p < q;
            p++)
        if (*p == '#')
        {
            q = p + 1;
            n = stack.ParseInt(s, (size_t) (p - s));
            for (i = 0; i < n; i++)
            {
                res = stack.Parse(L, q, (size_t) (l + s - q));
                if (res < 0)
                    return luaL_error(L, "fail to parse dice command");
                lua_pushinteger(L, res);
            }
            return n; // N#<dice_expr>
        }
    res = stack.Parse(L, s, l);
    if (res < 0)
        return luaL_error(L, "fail to parse dice command");
    lua_pushinteger(L, res);
    return 1; // <dice_expr>
}

/**
 * Dice(...)
 */
extern int Roll(lua_State * L)
{
    int nargs;
    // Dice1
    const char * s;
    size_t l;
    // Dice0
    lua_Integer count, dice;
    int status;

    // number of arguments
    nargs = lua_gettop(L);
    switch (nargs)
    {
        // Dice(str)
        case 1:
        {
            s = lua_tolstring(L, -1, &l);
            luaL_argcheck(L, s, 1, "invalid argument type");
            return Roll1(L, s, l);
        }
        // Dice(count, dice)
        case 2:
        {
            // validate argument type
            dice = lua_tointegerx(L, 2, &status);
            luaL_argcheck(L, status, 1, "invalid argument type");
            count = lua_tointegerx(L, 1, &status);
            luaL_argcheck(L, status, 2, "invalid argument type");
            dice &= 0xffff;
            count &= 0xffff;
            lua_pushinteger(L, Roll0(int(count), int(dice)));
            return 1;
        }
        default:
        {
            return luaL_error(L, "Invalid argument count");
        }
    }
}

// --{
int ArithmeticStack::IsOperator(char c)
{
    switch (c)
    {
        case '+':case '-':case '*':case '/':
        case 'D':
            return 1;
        default:
            return 0;
    }
}
int ArithmeticStack::IsDigit(char c)
{
    switch (c)
    {
        case '0':case '1':case '2':case '3':case '4':
        case '5':case '6':case '7':case '8':case '9':
            return 1;
        default:
            return 0;
    }
}
int ArithmeticStack::IsWhitespace(char c)
{
    return c == ' ';
}
int ArithmeticStack::ParseInt(const char * s, size_t l)
{
    int i, t;
    if (!s) throw new Error("Null pointer 's'");
    for (i = t = 0; i < l && IsDigit(s[i]); i++)
        t = t * 10 + s[i] - '0';
    return t;
}
int ArithmeticStack::Compare(char c)
{
    return stp.empty() || c
        && PRECEDENCE[c % 10] > PRECEDENCE[stp.top() % 10];
}

void ArithmeticStack::Calc()
{
    int a, b;
    char t;

    //printf("Calc\n");
    if (stn.size() < 2 || stp.size() < 1)
        throw new Error("Invalid ArithmeticStack state: (#stn=%i,#stp=%i)",
                stn.size(), stp.size());
    a = stn.top();  stn.pop();
    b = stn.top();  stn.pop();
    t = stp.top();  stp.pop();
    switch (t)
    {
        case '+':
            stn.push(b + a);
            break;
        case '-':
            stn.push(b - a);
            break;
        case '*':
            stn.push(b * a);
            break;
        case '/':
            stn.push(b / a);
            break;
        case 'D':
            stn.push(Roll0(b, a));
            break;
        default:
            throw new Error("Assertion error: operator stack corrupted");
    }
}

int ArithmeticStack::Parse(lua_State * L, const char * s, size_t l)
{
    char * p, * q, * r;
    char b[64];

    if (!s) return 0;
    if (l >= sizeof(b))
        throw new Error("Dice expr is too long!");
    if (!l) l = sizeof(b);
    // first scan to rule out invalid characters
    p = (char *) s;
    q = (char *) (p + l);
    r = (char *) b;
    for (; p < q; ++p)
        if (IsDigit(*p) || IsOperator(*p)
                || *p == '(' || *p == ')')
            *r++ = *p;
        else if (*p == 'd')
            *r++ = 'D';
        else if (!*p)
            break;
        else
            return luaL_error(L, "Invalid char in dice expr: '%c'", *p);
    //printf("ArithmeticStack> '%.*s'\n", l, b);
    // fill terminal zero
    *r++ = '\0';
    // initialize stacks
    while (!stn.empty()) stn.pop();
    while (!stp.empty()) stp.pop();
    // second scan to parse and calculate
    p = (char *) b;
    q = (char *) (p + l);

    //try
    //{
        while (p < q)
        {
            if (IsDigit(*p))
            {
                //printf("Encounter digit '%c'\n", *p);
                r = p;
                while (IsDigit(*++p) && p < q);
                stn.push(ParseInt(r, size_t(p - r)));
                continue;
            }
            if (IsOperator(*p) || !*p)
            {
                //if (*p) printf("Encounter operator '%c'\n", *p); else printf("Encounter terminal '\\0'\n");
                while (!Compare(*p) && !stp.empty())
                    Calc();
                if (!*p)
                    break;
                stp.push(*p++);
                continue;
            }
            if (*p == ')')
            {
                //printf("Encounter ')'\n");
                for (; !stp.empty() && stp.top() != '(';)
                    Calc();
                if (stp.empty())
                    return luaL_error(L, "Symbol '(' not found to match ')'");
                stp.pop();
                ++p;
                continue;
            }
            if (*p == '(')
            {
                //printf("Encounter '('\n");
                stp.push(*p++);
                continue;
            }
        }
        while (!stp.empty())
            Calc();
        //printf("Result = %i\n\n", stn.top());
        return stn.top();
    //}
    //catch (Error * e)
    //{
        //throw e;
    //}
}
// --}

