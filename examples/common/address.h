#ifndef ADDRESS_H
#define ADDRESS_H

/*  Manully set the address information 
    ***_R_F mean the argument order of
    ./swith_agent -i <order0> -i <order1>   */
#define CLIENT_MAC "3c:fd:fe:b3:12:cc"
#define SERVER_MAC "3c:fd:fe:b0:f5:24"
#define ATTACKER_MAC "3c:fd:fe:b5:00:4"
#define CLIENT_R_MAC "90:e2:ba:b3:bb:7c"
#define SERVER_R_MAC "90:e2:ba:b3:bb:7d"
#define ATTACKER_R_MAC "90:e2:ba:b3:bb:7c"
#define CLIENT_IP ("10.18.0.3")
#define SERVER_IP ("10.19.0.3")
#define ATTACKER_IP ("10.18.0.4")
#define CLIENT_R_IF_ORDER 0
#define SERVER_R_IF_ORDER 1
#define ATTACKER_R_IF_ORDER 0
#define MSS_536 0x18020402
#define MSS_1460 0xb4050402

/*  For server_en, XDP_DRV set to 1 if bind to xdp-drive mode
    Check the server's interface by ip addr show, then set
    SERVER_IF to that number    */
#define XDP_DRV 1
#define SERVER_IF 2



#endif
