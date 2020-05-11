//
//  NLSocket.cpp
//  MacSocket
//
//  Created by notblock on 2020/5/8.
//  Copyright © 2020 notblock. All rights reserved.
//

#include "NLSocket.hpp"

#include <stdio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <dispatch/dispatch.h>

//#include <string.h>
#include <iostream>
#include <cstring>
//#include <vertor>
#include <map>

namespace nlsdk {
    //连接人数
    std::map<int, char *> connecter;
    
    static int handle = 0;
    static dispatch_queue_t socket_rev_queue;
    static dispatch_queue_t socket_listen_queue;
    static const char * begin_tag = "<b>";
    static const char * end_tag = "<e>";
    
    
    char * socket_format_struct_msg(struct msg_struct msg);
    
    struct msg_struct socket_unpack_msg(char *msg);
    
    struct msg_struct socket_pack_struct_msg(struct msg_struct msg_stru, char *msg);
    
#pragma mark-公共方法
    /*-----------------------------------
     * 接收后解析接收到的套字节
     * 当解析出一条完整的数据后，调用rev_msg 返回给操作方处理
     ------------------------------------*/
    char *
    rev_pack(char *rev, socketbasic *self, int handle)
    {
        char *temp_a = rev;
        do {
            temp_a = strstr(temp_a, begin_tag);
            if (temp_a) {
                //            temp_a = (temp_a + 5);
                char *temp_b = strstr(temp_a, end_tag);
                if (temp_b) {
                    char *rev_temp = (char *)malloc(temp_b-temp_a - 2);
                    strlcpy(rev_temp, temp_a + 3, temp_b-temp_a - 2);
                    
                    self->rev_msg(rev_temp, handle);
                    free(rev_temp);
                    temp_a = temp_b+3;
                } else {
                    break;
                }
            } else {
                break;
            }
        } while (1);
        free(rev);
        return temp_a;
    }
    
    /*-----------------------------------
     * 接收后解析接收到的套字节
     * 当解析出一条完整的数据后，调用rev_msg 返回给操作方处理
     ------------------------------------*/
    int
    connet(socket_client *self)
    {
        struct sockaddr_in sockaddr;
        sockaddr.sin_len = sizeof(struct sockaddr_in);
        sockaddr.sin_family = AF_INET;
        sockaddr.sin_port = htons(12306);
        sockaddr.sin_addr.s_addr = inet_addr("127.0.0.1");
        
        int server_socket = socket(AF_INET, SOCK_STREAM, 0);
        if (server_socket == -1) {
            perror("socket error");
            return -10001;
        }
        printf("client will connect \n");
        if (connect(server_socket, (struct sockaddr *)&sockaddr, sizeof(struct sockaddr_in))==0)
        {
            handle = server_socket;
            
            dispatch_async(socket_rev_queue, ^{
                char recv_msg[1024];
                //connect 成功之后，其实系统将你创建的socket绑定到一个系统分配的端口上，且其为全相关，包含服务器端的信息，可以用来和服务器端进行通信。
                char *temp_rev = NULL;
                while (1) {
                    bzero(recv_msg, 1024);
                    long byte_num = recv(server_socket,recv_msg,1024,0);
                    
                    if (temp_rev != NULL) {
                        char *temp = (char *)malloc(strlen(temp_rev) + strlen(recv_msg));
                        strcat(temp, temp_rev);
                        strcat(temp, recv_msg);
                        free(temp_rev);
                        temp_rev = rev_pack(temp, self, server_socket);
                    } else {
                        char *temp = (char *)malloc(strlen(recv_msg));
                        strcpy(temp, recv_msg);
                        temp_rev = rev_pack(temp, self, server_socket);
                    }
                    
                    if (byte_num <= 0) {
                        break;
                    }
                }
                free(temp_rev);
                close(server_socket);
                printf("关闭链接\n");
            });
        } else {
            perror("connect error");
        }
        return 0;
    }
    
    int
    socket_listen(socket_server *self)
    {
        //服务器地址
        struct sockaddr_in server_addr;
        server_addr.sin_len = sizeof(struct sockaddr_in);
        server_addr.sin_family = AF_INET;//Address families AF_INET互联网地址簇
        server_addr.sin_port = htons(12306);
        server_addr.sin_addr.s_addr = inet_addr("0.0.0.0");
        bzero(&(server_addr.sin_zero),8);
        
        //创建socket
        int server_socket = socket(AF_INET, SOCK_STREAM, 0);//SOCK_STREAM 有连接
        if (server_socket == -1) {
            perror("socket error\n");
            return 1;
        }
        //绑定socket：将创建的socket绑定到本地的IP地址和端口，此socket是半相关的，只是负责侦听客户端的连接请求，并不能用于和客户端通信
        int bind_result = bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr));
        if (bind_result == -1) {
            perror("bind error");
            return 1;
        }
        //listen侦听 第一个参数是套接字，第二个参数为等待接受的连接的队列的大小，在connect请求过来的时候,完成三次握手后先将连接放到这个队列中，直到被accept处理。如果这个队列满了，且有新的连接的时候，对方可能会收到出错信息。
        if (listen(server_socket, 1000) == -1) {
            perror("listen error");
            return 1;
        }
        printf("server listenning\n");
        dispatch_async(socket_listen_queue, ^{
            do {
                printf("wait client\n");
                struct sockaddr_in client_address;
                socklen_t address_len = sizeof(struct sockaddr_in);
                int client_socket = accept(server_socket, (struct sockaddr *)&client_address, &address_len);
                connecter.insert(std::map<int, char*>::value_type(client_socket, inet_ntoa(client_address.sin_addr)));
                printf("%s\n", inet_ntoa(client_address.sin_addr));
                //返回的client_socket为一个全相关的socket，其中包含client的地址和端口信息，通过client_socket可以和客户端进行通信。
                if (client_socket == -1) {
                    connecter.erase(client_socket);
                    continue;
                }
                dispatch_async(socket_rev_queue, ^{
                    char recv_msg[1024];
                    //connect 成功之后，其实系统将你创建的socket绑定到一个系统分配的端口上，且其为全相关，包含服务器端的信息，可以用来和服务器端进行通信。
                    char *temp_rev = NULL;
                    while (1) {
                        bzero(recv_msg, 1024);
                        ssize_t byte_num = recv(server_socket,recv_msg,1024,0);
                        
                        if (temp_rev != NULL) {
                            char *temp = (char *)malloc(strlen(temp_rev) + strlen(recv_msg));
                            strcat(temp, temp_rev);
                            strcat(temp, recv_msg);
                            free(temp_rev);
                            temp_rev = rev_pack(temp, self, server_socket);
                        } else {
                            char *temp = (char *)malloc(strlen(recv_msg));
                            strcpy(temp, recv_msg);
                            temp_rev = rev_pack(temp, self, server_socket);
                        }
                        
                        if (byte_num <= 0) {
                            break;
                        }
                    }
                    free(temp_rev);
                    close(client_socket);
                    connecter.erase(client_socket);
                    printf("关闭客户机链接 %d", client_socket);
                });
                
                
            } while (1);
            
        });
        
        return 0;
    }
    
    char * socket_format_struct_msg(struct msg_struct msg) {
        char *m = (char*)(malloc(strlen(msg.msg) + 6 + 36 + 10 + 80 + 80 + 1 + 1));
        sprintf(m, "%sl:%ld\ni:%s\nf:%s\no:%s\nz:%s\nd:%s\np:%d\n%s",begin_tag, msg.size, msg.id, msg.from, msg.to, msg.zip, msg.msg, msg.type, end_tag);
        return m;
    }
    static const char nullchar = '\0';
    struct msg_struct socket_unpack_msg(char *msg) {
        char *temp = nullptr;
        struct msg_struct s;
        memset(&s, 0, sizeof(s));
        while ((temp = strsep(&msg, "\n"))) {
            if ( *temp == nullchar) {
                break;
            } else {
//                s = socket_pack_struct_msg(s, temp);
            }
        }
        return s;
    }
    
    /**
     解析收到的数据
     */
    struct msg_struct socket_pack_struct_msg(struct msg_struct msg_stru, char *msg) {
        char *temp_struct_name = strchr(msg, ':');
        switch (*msg) {
            case 100://data
            {
                temp_struct_name++;
                memset(msg_stru.msg, 0, strlen(msg_stru.msg));
                msg_stru.msg = (char *)malloc(strlen(temp_struct_name) + 1);
                strcpy(msg_stru.msg, temp_struct_name);
            }
                break;
            case 105://id
                temp_struct_name++;
                strcpy(msg_stru.id, temp_struct_name);
                break;
            case 111://to
                temp_struct_name++;
                strcpy(msg_stru.to, temp_struct_name);
                break;
            case 122://ziptype
                temp_struct_name++;
                strcpy(msg_stru.zip, temp_struct_name);
                break;
            case 102://from
                temp_struct_name++;
                strcpy(msg_stru.from, temp_struct_name);
                break;
            case 108://length
                temp_struct_name++;
                msg_stru.size = atoi(temp_struct_name);
                break;
            case 112://type
                temp_struct_name++;
                msg_stru.type = atoi(temp_struct_name);
                break;
            default:
                break;
        }
        //        free(temp_struct_name);
        return msg_stru;
    }
    
#pragma mark- fwq
    socket_server::
    socket_server()
    {
        socket_rev_queue = dispatch_queue_create("com.nlsocket.client", DISPATCH_QUEUE_CONCURRENT);
        socket_listen_queue = dispatch_queue_create("com.nlsocket.listen", DISPATCH_QUEUE_CONCURRENT);
    }
    
    socket_server::
    socket_server(int port,const char *ip_addr)
    {
        this->port = port;
        this->ip_addr = ip_addr;
        socket_rev_queue = dispatch_queue_create("com.nlsocket.client", DISPATCH_QUEUE_CONCURRENT);
    }
    int
    socket_server::
    server_start(int port, const char *ip_addr)
    {
        this->port = port;
        this->ip_addr = ip_addr;
        return socket_listen(this);
    }
    
    int
    socket_server::
    server_start()
    {
        return socket_listen(this);
    }
    //发送出去
    int
    socket_server::
    rev_msg(char *msg, int handle)
    {
        struct msg_struct msg_stru = socket_unpack_msg(msg);
        ((void(*)(char *))(this->post_msg))(msg_stru.msg?:NULL);//1st function call argument is an uninitialized value
        free(msg_stru.msg);
        strcpy(msg_stru.from, "s");
        strcpy(msg_stru.to, "b");
        msg_stru.msg = (char *)malloc(2);
        strcpy(msg_stru.msg, "o");
        this->send_msg(msg_stru, handle);
        free(msg_stru.msg);
        msg_stru.msg = NULL;
        //        free(msg_stru->from[80]);
        //        free(msg_stru->to);
        //        free(msg_stru->id);
        //        free(msg_stru->zip);
        
        return 0;
    }
    
    //设置发送接口
    void
    socket_server::
    set_post_msg_handle(void *post_msg)
    {
        this->post_msg = post_msg;
    }
    
    
    int
    socket_server::
    stop()
    {
        close(handle);
        return 0;
    }
    
    int
    socket_server::
    send_msg(struct msg_struct m , int handle)
    {
        char *mc = socket_format_struct_msg(m);
        printf("发送给:%d\t%s", handle, mc);
        if (send(handle, mc, strlen(mc), 0) != 0) {
            perror("服务端发送失败:");
        }
        free(mc);
        return 0;
    }
    
    socket_server::
    ~socket_server()
    {
        delete ip_addr;
        ip_addr = 0;
    }
    
    
#pragma mark- socket client
    
    socket_client::
    socket_client()
    {
        socket_rev_queue = dispatch_queue_create("com.nlsocket.client", NULL);
    }
    
    socket_client::
    socket_client(int port,const char *ip_addr)
    {
        this->port = port;
        this->ip_addr = ip_addr;
        socket_rev_queue = dispatch_queue_create("com.nlsocket.client", NULL);
    }
    
    
    
    int
    socket_client::
    client_start(int port,const char *ip_addr)
    {
        this->port = port;
        this->ip_addr = ip_addr;
        return connet(this);
    }
    
    int
    socket_client::
    client_start()
    {
        return connet(this);
    }
    //发送出去
    int
    socket_client::
    rev_msg(char *msg, int handle)
    {
        struct msg_struct msg_stru = socket_unpack_msg(msg);
        ((void(*)(char *))(this->post_msg))(msg_stru.msg?:NULL);
        free(msg_stru.msg);
        return 0;
    }
    
    //设置发送接口
    void
    socket_client::
    set_post_msg_handle(void *post_msg)
    {
        this->post_msg = post_msg;
    }
    
    
    int
    socket_client::
    stop()
    {
        close(handle);
        return 0;
    }
    
    int
    socket_client::
    send_msg(const char *msg)
    {
        struct msg_struct m;
        m.msg = (char *)malloc(strlen(msg));
        strcpy(m.msg, msg);
        char *mc = socket_format_struct_msg(m);
        send(handle, mc, strlen(mc), 0);
        free(m.msg);
        free(mc);
        return 0;
    }
    
    char *
    socket_client::
    ip_address()
    {
        char *temp = (char *)malloc(sizeof(char));
        strcpy(temp, this->ip_addr);
        return temp;
    }
    
    socket_client::
    ~socket_client()
    {
        delete ip_addr;
        ip_addr = 0;
    }
}


