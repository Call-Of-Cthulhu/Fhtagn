#ifndef EXCEPTION_H
#define EXCEPTION_H

class Error
{
public:
    Error(const char *, ...);
    ~Error();
    Error * GetCause();
    Error * SetCause(Error *);
    void PrintMessage();
private:
    char msg[1024];
    int level;
    Error * cause;
};
#endif /* EXCEPTION_H */
