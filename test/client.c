#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
#include <arpa/inet.h>

int main()
{
    int sock=socket(AF_INET,SOCK_STREAM,0);
    if(sock==-1)
    {
        printf("socket error\n");
        return -1;
    }
    struct sockaddr_in info;
    bzero(&info,sizeof(info));
    info.sin_family=PF_INET;
    info.sin_addr.s_addr=inet_addr("10.19.0.3");
    info.sin_port=htons(80);
    if(connect(sock,(struct sockaddr*)&info,sizeof(info))==-1)
    {
        printf("connect error\n");
        return -1;
    }
    return 0;
}