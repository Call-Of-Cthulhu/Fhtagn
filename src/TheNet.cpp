#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
//#include <regex>
#include <sys/time.h>

#include "TheNet.h"
#include "Error.hpp"

#ifdef ADDRLEN
    #undef ADDRLEN
#endif
#define ADDRLEN     sizeof(struct sockaddr)

#define CHUNK_SIZE  4096

#define TEXT_ECHO   "CTHULHU_FHTAGN"

#define ServerAPI   Server::
#define ClientAPI   Client::
using namespace std;

//struct timezone {
//    int tz_minuteswest; // minutes west of Greenwich
//    int tz_dsttime;     // type of DST correction
//};
//static const struct timezone TZ_CHINA = {0};

static void InitSocket(int fd)
{
    static const int opt_timestamp = 1;
    int status;

    status = setsockopt(fd, SOL_SOCKET, SO_TIMESTAMP,
            (const void *) &opt_timestamp,
            (socklen_t) sizeof(opt_timestamp));
    if (status == -1)
    {
        perror("setsockopt SO_TIMESTAMP");
    }
}

// @man setsockopt(2)
// @man getprotoent(3)
// @man protocols(5)
// optval = 1;
// optlen = sizeof(optval);
//setsockopt(fd, SOL_SOCKET, SO_TIMESTAMP,
//     (const void *) optval, (socklen_t) optlen);
ServerAPI Server(int port)
{
    SocketAddress   my_addr;

    fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0)
    {
        perror("Server:Server socket");
        fd = 0;
        throw new Error("Fail to create server socket");
    }

    memset(&my_addr, 0, sizeof(my_addr));
    my_addr.sin_family      = AF_INET;
    my_addr.sin_port        = htons(port);
    my_addr.sin_addr.s_addr = htons(INADDR_ANY);

    if (bind(fd, (struct sockaddr *) &my_addr, ADDRLEN) < 0)
    {
        perror("Server:Server bind");
        close(fd);
        fd = 0;
        throw new Error("Fail to bind server socket");
    }

    InitSocket(fd);
    isclosing = 0;
    isclosed = 0;
}

void ServerAPI Start()
{
    ssize_t                 nbits;
    char                    buff[CHUNK_SIZE];
    int                     s;
    char                    host[NI_MAXHOST];
    struct msghdr           hdr;
    struct iovec            iov;
    SocketAddress           addr;

    if (!fd) return;
    memset(&hdr, 0, sizeof(hdr));
    hdr.msg_name        = (void *) &addr;
    hdr.msg_namelen     = (socklen_t) sizeof(addr);
    hdr.msg_iov         = &iov;
    hdr.msg_iovlen      = (size_t) 1;
    iov.iov_base        = (void *) buff;
    for (nbits = CHUNK_SIZE; !IsClosing();)
    {
        memset(buff, 0, nbits);
        memset(&addr, 0, sizeof(addr));
        iov.iov_len     = (size_t) CHUNK_SIZE;
        nbits = recvmsg(fd, &hdr, 0);
        if (nbits < 0)
        {
            perror("Server:Start recvmsg");
            continue;
        }

        if (strcoll(buff, TEXT_ECHO) == 0)
        {
            iov.iov_len = (size_t) nbits;
            if (sendmsg(fd, &hdr, 0) != nbits)
            {
                perror("Server:Start sendmsg");
                fprintf(stderr, "Fail to send response\n");
            }
            continue;
        }

        s = getnameinfo((struct sockaddr *) &addr, sizeof(addr),
                (char *) host, (size_t) NI_MAXHOST,
                (char *) NULL, (size_t) 0,
                (int) NI_NUMERICSERV);
        if (s == 0)
        {
            printf("Received %ld bytes from %s {\n%.*s\n}\n",
                    (long) nbits, host, nbits, buff);
        }
        else
        {
            fprintf(stderr, "Fail to getnameinfo: %s\n", gai_strerror(s));
        }
    }

    isclosed = 1;
}

ServerAPI ~Server()
{
    close(fd);
    fd = 0;
}

void ServerAPI Close()
{
    isclosing = 1;
}

bool ServerAPI IsClosing()
{
    return isclosing;
}

bool ServerAPI IsClosed()
{
    return isclosed;
}

ClientAPI Client()
{
    isclosing = 0;
    isclosed = 0;
}

ClientAPI ~Client()
{
    close(fd);
    fd = 0;
}

void ClientAPI Connect(const char * s_ip, int port)
{
    char                    s_port[6]; // max port 5:"65536"
    struct addrinfo         hints;
    struct addrinfo *       result;
    struct addrinfo *       rp;
    int                     s;
    size_t                  len;

    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family         = AF_INET;
    hints.ai_socktype       = SOCK_DGRAM;
    hints.ai_flags          = 0;
    hints.ai_protocol       = 0;

    snprintf(s_port, sizeof(s_port), "%i", port);
#ifdef DEBUG
    printf("Connect [ %s:%s ] ... ", s_ip, s_port);
#endif
    s = getaddrinfo(s_ip, s_port, &hints, &result);
    if (s != 0)
        //throw new Error("Fail to getaddrinfo");
        throw new Error("Fail to getaddrinfo: %s", gai_strerror(s));

    for (rp = result; rp != NULL; rp = rp->ai_next)
    {
        fd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
        if (fd == -1)
            continue;
        if (connect(fd, rp->ai_addr, rp->ai_addrlen) != -1)
            break;
        close(fd);
    }

    if (rp == NULL)
    {
        freeaddrinfo(result);
        throw new Error("Sevice not available!");
    }

    InitSocket(fd);
    // store
    memcpy(&dest, rp->ai_addr, sizeof(dest));
    freeaddrinfo(result);
#ifdef DEBUG
    printf("[Done]\n");
#endif
}

#define MILLION             (1000000)
void ClientAPI Start(unsigned int time)
{
    size_t                  len;
    ssize_t                 nbits;
    // datagram
    struct msghdr           msg;
    struct iovec            iov;
    // data
    char                    buff[CHUNK_SIZE];
    // ancillary data
    char                    ctrl[CMSG_SPACE(sizeof(struct timeval))];
    struct cmsghdr *        cmsg;
    struct timeval          tv, tvNow, tvRes;
    uint64_t                ddwNow, ddwTv;

    len                 = strlen(TEXT_ECHO) + 1;
    // initialize 'msg'
    msg.msg_name        = (void *) &dest;           // optional address
    msg.msg_namelen     = (socklen_t) sizeof(dest); // size of address
    msg.msg_iov         = (struct iovec *) &iov;    // scatter/gather array
    msg.msg_iovlen      = (size_t) 1;               // array element count
    for (nbits = CHUNK_SIZE; !IsClosing();)
    {
        memset(buff, 0, nbits);
        ////////////////////////////////////////////////
        // Send data
        ////////////////////////////////////////////////
        // Scatter/gather array items
        // @man readv(2)
        iov.iov_base        = (void *) TEXT_ECHO;   // starting address
        iov.iov_len         = (size_t) len;         // transfer count
        msg.msg_control     = (void *) 0;           // ancillary data
        msg.msg_controllen  = (size_t) 0;           // ancillary data len
        msg.msg_flags       = (int) 0;
        // send
        nbits = sendmsg(fd, &msg, 0);
        if (nbits != len)
        {
            perror("Client:Start sendmsg");
            Close();
            isclosed = 1;
            throw new Error("IO error: fail to write (%i)", nbits);
        }
        ////////////////////////////////////////////////
        // Recv data
        ////////////////////////////////////////////////
        iov.iov_base        = (void *) buff;
        iov.iov_len         = (size_t) CHUNK_SIZE;
        msg.msg_control     = (void *) ctrl;        // ancillary data
        msg.msg_controllen  = (size_t) sizeof(ctrl);// ancillary data len
        msg.msg_flags       = (int) 0;
        memset(ctrl, 0, sizeof(ctrl));
        // recv
        nbits = recvmsg(fd, &msg, 0);
        if (nbits == -1)
        {
            perror("Client:Start recvmsg");
            Close();
            isclosed = 1;
            throw new Error("IO error: fail to read (%i)", nbits);
        }
        // @man cmsg(3)
        for(cmsg = CMSG_FIRSTHDR(&msg);
                cmsg != NULL;
                cmsg = CMSG_NXTHDR(&msg, cmsg))
        {
            if (cmsg->cmsg_level == SOL_SOCKET
                    && cmsg->cmsg_type == SO_TIMESTAMP
                    && cmsg->cmsg_len == CMSG_LEN(sizeof(tv)))
            {
                //struct timeval {
                //    time_t        tv_sec;  // seconds
                //    suseconds_t   tv_usec; // microseconds
                //};
                // @man timeradd(3)
                memcpy(&tv, CMSG_DATA(cmsg), sizeof(tv));
                if (gettimeofday(&tvNow, NULL) == -1)
                {
                    perror("gettimeofday");
                    break;
                }
                timersub(&tvNow, &tv, &tvRes);
                ddwNow = tvNow.tv_sec * MILLION + tvNow.tv_usec;
                ddwTv = tv.tv_sec * MILLION + tv.tv_usec;
                printf("Now: %llu Tv: %llu dff: %llu\n",
                        ddwNow, ddwTv, (ddwNow - ddwTv) / MILLION);
                continue;
            }
            printf("{level:%i,type:%i,len:%i}\n",
                    cmsg->cmsg_level, cmsg->cmsg_type, cmsg->cmsg_len);
        }
        printf("Sleep %i ...\n", time);
        sleep(time);
    }

    isclosed = 1;
}
#undef MILLION

void ClientAPI Close()
{
    isclosing = 1;
}

bool ClientAPI IsClosing()
{
    return isclosing;
}

bool ClientAPI IsClosed()
{
    return isclosed;
}

void ClientAPI Send(const char * msg, int len)
{
    int                     nbits;
    char *                  ptr;
    struct msghdr           hdr;
    struct iovec            iov;

    if (!fd) return;
    memset(&hdr, 0, sizeof(hdr));
    hdr.msg_name        = (void *) &dest;
    hdr.msg_namelen     = (socklen_t) sizeof(dest);
    hdr.msg_iov         = &iov;
    hdr.msg_iovlen      = (size_t) 1;
    for (ptr = (char *) msg; len > 0;)
    {
        iov.iov_base    = (void *) ptr;
        if (len < CHUNK_SIZE)
            iov.iov_len = (size_t) len;
        else
            iov.iov_len = (size_t) CHUNK_SIZE;
        nbits = sendmsg(fd, &hdr, 0);
        if (nbits < 0)
        {
            perror("Client:Send sendmsg");
            throw new Error("IO error");
        }
        len -= nbits;
        ptr += nbits;
    }
}
