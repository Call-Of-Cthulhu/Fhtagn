#ifndef THENET_H
#define THENET_H

#include <arpa/inet.h>
#include <errno.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>

#include <map>
#include <uuid/uuid.h>

typedef struct sockaddr_in              SocketAddress;
typedef int                             ServerSocket;
typedef int                             Socket;
typedef unsigned long                   InetAddress;
typedef struct
{
    uuid_t          uuid;
    InetAddress     addr;
    int             port;
}                                       ClientHandle;
typedef std::map<InetAddress, ClientHandle>  ClientMap;

class Server
{
public:
    Server(int);
    ~Server();

    void            Start();
    void            Close();
    bool            IsClosing();
    bool            IsClosed();
protected:
    ServerSocket    fd;
private:
    bool            isclosing;
    bool            isclosed;
};

class Client
{
public:
    Client();
    ~Client();

    void            Connect(const char *, int);
    void            Start(unsigned int);
    void            Close();
    bool            IsClosing();
    bool            IsClosed();
    void            Send(const char *, int);
protected:
    Socket          fd;
private:
    SocketAddress   dest;
    bool            isclosing;
    bool            isclosed;
};

#endif /* THENET_H */
