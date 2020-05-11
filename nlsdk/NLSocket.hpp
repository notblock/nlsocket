//
//  NLSocket.hpp
//  MacSocket
//
//  Created by notblock on 2020/5/8.
//  Copyright © 2020 notblock. All rights reserved.
//

#ifndef NLSocket_hpp
#define NLSocket_hpp

#include <stdio.h>

namespace nlsdk {
    
    typedef int Server_typs;
    
    enum server_type_enum {
        connect_msg = 0,
        heart_msg,
        leave_msg,
        custom_msg
    };
    
    /**
     消息结构体
     */
    struct msg_struct {
        char id[36];//消息uuid
        char *msg;//消息体
        size_t size;//消息大小
        char zip[10];//压缩协议
        char from[80];//来自
        char to[80];//发送到
        Server_typs type;//消息协议
    };
    
    class socketbasic {
    public:
        virtual int rev_msg(char *msg, int handle) = 0;
    };
    
    
    
    class socket_server:public socketbasic {
        
    public:
        socket_server();
        
        explicit socket_server(int port,const char *ip_addr);
        
        int server_start(int port,const char *ip_addr);
        
        int server_start();
        
        int stop();
        
        int send_msg(struct msg_struct m, int handle);
        
        int rev_msg(char *msg, int handle);
        
        void set_post_msg_handle(void *post_msg);
        
        ~socket_server();
    private:
        
        int port;
        
        int socket_handle;
        
        int time_heart;
        
        const char *ip_addr;
        
        void *post_msg;
        
    };
    
    class socket_client:public socketbasic {
        
    public:
        socket_client();
        
        explicit socket_client(int port,const char *ip_addr);
        
        int client_start(int port,const char *ip_addr);
        
        int client_start();
        
        int stop();
        
        int send_msg(const char *msg);
        
        int rev_msg(char *msg, int handle);
        
        void set_post_msg_handle(void *post_msg);
        
        char* ip_address();
        
        ~socket_client();
    private:
        
        int port;
        
        int socket_handle;
        
        int time_heart;
        
        const char *ip_addr;
        
        void *post_msg;
        
    };
    
}

#endif /* NLSocket_hpp */
