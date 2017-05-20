#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/types.h>

//#include "TheSim.h"
#include "TheNet.h"
#include "Error.hpp"

//#define MAIN_SCRIPT "data/Mythos/data/scripts/main.lua"
//#define TEST_SCRIPT "test.lua"
#define TEXT_QUIT "q"

int test_server();
int test_client();

int main(int count, char ** argv)
{
    try
    {
#ifdef TEST_SERVER
        test_server();
#else
        test_client();
#endif
    }
    catch (Error * err)
    {
        err->PrintMessage();
        delete err;
    }
    return EXIT_SUCCESS;
}

int test_server()
{
    char input[128];
    Server server{2333};
    pid_t th;

    printf("Server starting ...\n");

    th = fork();
    if (th == -1)
    {
        perror("test_server fork");
        throw new Error("Fail to fork server");
    }
    if (th == 0)    // child process
    {
        server.Start();
    }
    else            // main process
    {
        printf("Server started\n");
        for (;;)
        {
            scanf("%s", input);
            printf("Server received local command '%s'\n", input);
            if (!strcoll(input, TEXT_QUIT))
            {
                server.Close();
                kill(th, SIGKILL);
                break;
            }
        }
    }

    return EXIT_SUCCESS;
}

int test_client()
{
    char input[128];
    Client client{};
    pid_t th;

    client.Connect("localhost", 2333);
    printf("Client connected.\n");

    th = fork();
    if (th == -1)
    {
        perror("test_server fork");
        throw new Error("Fail to fork server");
    }
    if (th == 0)    // child process
    {
        client.Start(1000);
    }
    else            // main process
    {
        printf("Client started\n");
        for (;;)
        {
            scanf("%s", input);
            printf("Client send '%s'\n", input);
            client.Send(input, strlen(input));
            if (!strcoll(input, TEXT_QUIT))
            {
                client.Close();
                kill(th, SIGKILL);
                break;
            }
        }
    }

    return EXIT_SUCCESS;
}
