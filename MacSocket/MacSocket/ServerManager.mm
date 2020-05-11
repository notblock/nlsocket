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

#import "ServerData.h"


#define LOG(A,...)  [self logWithString:[NSString stringWithFormat:A , ##__VA_ARGS__]]



typedef enum : NSUInteger {
    NL_SOCKET_TYPE_SERVER = 0, //服务器一般信息
    NL_SOCKET_TYPE_NOTIFICATION = 1,//服务器通知
    
} NL_SOCKET_SERVER_TYPE;

//struct socket_msg {
//public:
//    socket_msg(int l, char *mid, char *fm, char *t, char *data, long date):length(l), msgid(mid), frome(fm), to(t), data(data), date(date) {
//
//    };
//private:
//    int length;
//    char *msgid;
//    char *frome;
//    char *to;
//    char *token;
//    char *data;
//    long date;
//};




@interface ServerManager()
{
    dispatch_queue_t mainqueue;
    dispatch_queue_t clientqueue;
}


@end

@implementation ServerManager

-(id)init {
    self = [super init];
    if (self) {
        mainqueue = dispatch_queue_create("com.notblock.socket_main", DISPATCH_QUEUE_CONCURRENT);
        clientqueue = dispatch_queue_create("com.notblock.socket_clients", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)logWithString:(NSString *)str {
    self.logString([str stringByAppendingString:@"\n"]);
}

- (int)start:(NSString *)ipAddress {
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
    LOG(@"server listen");
    //listen侦听 第一个参数是套接字，第二个参数为等待接受的连接的队列的大小，在connect请求过来的时候,完成三次握手后先将连接放到这个队列中，直到被accept处理。如果这个队列满了，且有新的连接的时候，对方可能会收到出错信息。
    if (listen(server_socket, 1000) == -1) {
        perror("listen error");
        return 1;
    }
    
//    struct sockaddr_in client_address;
//    socklen_t address_len;
    printf("server accept\n");
    
    LOG(@"开启队列");
    dispatch_async(mainqueue, ^{
        do {
            struct sockaddr_in client_address;
            socklen_t address_len;
            LOG(@"等待接受客户端");
            int client_socket = accept(server_socket, (struct sockaddr *)&client_address, &address_len);
            //保存客户端信息
            [self saveClientItem:client_socket WithIp:client_address.sin_addr];
            LOG(@"接受客户端%d \t 客户端地址:%s", client_socket, inet_ntoa(client_address.sin_addr));
            //返回的client_socket为一个全相关的socket，其中包含client的地址和端口信息，通过client_socket可以和客户端进行通信。
            if (client_socket == -1) {
                LOG(@"socket创建失败");
                continue;
            }
            //通知所有客户机
            [self notificationAll:nil];
            dispatch_async(self->clientqueue, ^{
                //接受客户机的消息
                [self recv:client_socket];
            });
        } while (1);
    });
    
    return 0;
}

- (void)saveClientItem:(int)client_socket WithIp:(struct  in_addr )sin_addr {
    ClientItem *item = nil;
    NSString *client_address_str = [NSString stringWithFormat:@"%s", inet_ntoa(sin_addr)];
    if ([ServerData shareInstance].userInfoDic[client_address_str]) {
        item = [ServerData shareInstance].userInfoDic[client_address_str];
        if (item.handle != client_socket) {
            item = [[ClientItem alloc] init];
            item.ip_address = client_address_str;
            item.handle = client_socket;
            [[ServerData shareInstance] setUserInfo:@{item.ip_address:item}];
        }
    } else {
        item = [[ClientItem alloc] init];
        item.ip_address = client_address_str;
        item.handle = client_socket;
        [[ServerData shareInstance] setUserInfo:@{item.ip_address:item}];
    }
}


/**
 通知所有线上用户
 */
- (void)notificationAll:(NSDictionary *)userInfos {
//    static struct socket_msg rev_msg = socket_msg(<#int l#>, <#char *mid#>, <#char *fm#>, <#char *t#>, <#char *data#>, <#long date#>)
    NSMutableArray *sendArr = [[NSMutableArray alloc] initWithCapacity:[[ServerData shareInstance].userInfoDic count]];
    for (ClientItem *item in [[ServerData shareInstance].userInfoDic allValues]) {
        [sendArr addObject:item.ip_address];
    }
    for (ClientItem *item in [[ServerData shareInstance].userInfoDic allValues]) {
        [self forword:item.handle msg:sendArr];
    }
}

/**
 开启单个client通信
 */
- (void)recv:(int)client_socket {
    long byte_num = 0;
    char recv_msg[1024];
    do {
        //单次接受1024，拼装
        bzero(recv_msg, 1024);
        byte_num = recv(client_socket,recv_msg,1024,0);
        NSData *data = [NSData dataWithBytes:recv_msg length:strlen(recv_msg)];
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error) {
            LOG(@"接收数据解析错误:%@", error);
        }
        [self forward:client_socket fromData:json];
        //发送0字节时，断开连接
    } while (byte_num > 0);
    self.clientBlock(client_socket, [NSString stringWithFormat:@"client:%d,退出", client_socket]);
    close(client_socket);
}

- (void)forword:(int)client_socket msg:(id)sendArr {
    NSData *sendJson = [NSJSONSerialization dataWithJSONObject:sendArr options:0 error:0];
    send(client_socket, sendJson.bytes, sendJson.length, 0);
}

-(void)send:(int)client_socket msg:(NSString *)msg {
    static NSString *
    send(client_socket, msg.UTF8String, strlen(msg.UTF8String), 0);
}

- (void)sendNotification:(int)handle {
    
}
- (void)forward:(int)handle fromData:(NSDictionary *)json {
    ClientItem *item = [ServerData shareInstance].userInfoDic[json[@"f"]];
    if (item) {
        [self send:item.handle msg:json[@"m"]];
    } else {
        [self forword:handle msg:@{@"m":@"该设备没有上线"}];
    }
}



@end
