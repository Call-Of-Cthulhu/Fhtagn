#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "Error.hpp"

Error::Error(const char * fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    vsnprintf(msg, sizeof(msg), fmt, ap);
    va_end(ap);

    level = 0;
    cause = NULL;
}

Error::~Error()
{
    if (cause)
    {
        delete cause;
        cause = NULL;
    }
}

Error * Error::GetCause()
{
    return cause;
}

Error * Error::SetCause(Error * ex)
{
    cause = ex;
    cause->level = level + 1;
    return this;
}

void Error::PrintMessage()
{
    static const char indent[] = "    ";
    char * prefix, * buffer;
    int i;

    buffer = NULL;
    prefix = (char *) (level > 0
            ? (buffer = (char *) malloc(sizeof(indent) * level))
            : "");
    for (i = 0; i < level; i += sizeof(indent))
    {
        memcpy(&(prefix[i]), indent, sizeof(indent));
    }
    printf("%s%s\n", prefix, msg);
    if (cause)
    {
        printf("%sCaused by:\n", prefix);
        cause->PrintMessage();
    }
    free(buffer);
}


