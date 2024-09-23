#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

int main()
{
    char buf[8192];
    char request[1024];
    char request_template[]="GET / HTTP/1.1\r\nHost: %s\r\n\r\n";
    int request_len=snprintf(request,1024,request_template,"10.19.0.3");
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
    int total=0,last;
    while(total<request_len)
    {
	last=write(sock,request+total,request_len-total);
	if(last==-1)
	{
	    perror("write");
	    exit(-1);
	}
	total+=last;
    }
    while((total=read(sock,buf,8192))>0);
    if(total==-1) exit(-1);
    return 0;
}
