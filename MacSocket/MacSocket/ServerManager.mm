//
//  ServerManager.m
//  MacSocket
//
//  Created by notblock on 2020/4/12.
//  Copyright © 2020 notblock. All rights reserved.
//

#import "ServerManager.h"

#include <stdio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define LOG(A,...)  [self logWithString:[NSString stringWithFormat:A , ##__VA_ARGS__]]

@interface ServerManager()
{
    dispatch_queue_t mainqueue;
}


@end

@implementation ServerManager

-(id)init {
    self = [super init];
    if (self) {
        mainqueue = dispatch_queue_create("com.notblock.socket_main", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)logWithString:(NSString *)str {
    self.logString([str stringByAppendingString:@"\n"]);
}

- (int)start:(NSString *)ipAddress {
    //服务器地址
    LOG(@"服务器开始运行，当前服务器ip：%@", ipAddress);
//    self.logString([NSString stringWithFormat:@"服务器开始运行，当前服务器ip：%@\n", ipAddress]);
    struct sockaddr_in server_addr;
    server_addr.sin_len = sizeof(struct sockaddr_in);
    server_addr.sin_family = AF_INET;//Address families AF_INET互联网地址簇
    server_addr.sin_port = htons(12306);
    server_addr.sin_addr.s_addr = inet_addr("0.0.0.0");
    bzero(&(server_addr.sin_zero),8);
    
    //创建socket
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);//SOCK_STREAM 有连接
    if (server_socket == -1) {
        LOG(@"socket创建失败");
        return 1;
    }
    
    //绑定socket：将创建的socket绑定到本地的IP地址和端口，此socket是半相关的，只是负责侦听客户端的连接请求，并不能用于和客户端通信
    int bind_result = bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (bind_result == -1) {
        LOG(@"bind 失败");
        return 1;
    }
    printf("server listen\n");
    //listen侦听 第一个参数是套接字，第二个参数为等待接受的连接的队列的大小，在connect请求过来的时候,完成三次握手后先将连接放到这个队列中，直到被accept处理。如果这个队列满了，且有新的连接的时候，对方可能会收到出错信息。
    if (listen(server_socket, 1000) == -1) {
        LOG(@"listen 失败");
        return 1;
    }
    LOG(@"开启队列，accept");
    dispatch_async(mainqueue, ^{
        struct sockaddr_in client_address;
        socklen_t address_len;
        int client_socket = accept(server_socket, (struct sockaddr *)&client_address, &address_len);
        
        //返回的client_socket为一个全相关的socket，其中包含client的地址和端口信息，通过client_socket可以和客户端进行通信。
        if (client_socket == -1) {
            LOG(@"socket创建失败");
        }
        [self recv:client_socket];
//        char recv_msg[1024];
//
//
//        char reply_msg[1024];
        
            
            
            
//            bzero(recv_msg, 1024);
//            bzero(reply_msg, 1024);
//
//            printf("reply:");
//            scanf("%s",reply_msg);
//            send(client_socket, reply_msg, 1024, 0);
//
//            long byte_num = recv(client_socket,recv_msg,1024,0);
//            recv_msg[byte_num] = '\0';
//            printf("client said:%s\n",recv_msg);
        
    });
    
    return 0;
}

- (void)recv:(int)client_socket {
    while (1) {
        char recv_msg[1024];
        bzero(recv_msg, 1024);
        
        long byte_num = recv(client_socket,recv_msg,1024,0);
        recv_msg[byte_num] = '\0';
        NSString *msg = [NSString stringWithUTF8String:recv_msg];
        self.clientBlock(client_socket, msg);
    }
}

-(void)send:(int)client_socket msg:(NSString *)msg {
    send(client_socket, msg.UTF8String, strlen(msg.UTF8String), 0);
}


@end
