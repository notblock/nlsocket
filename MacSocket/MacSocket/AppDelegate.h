//
//  AppDelegate.h
//  MacSocket
//
//  Created by notblock on 2020/4/12.
//  Copyright © 2020 notblock. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "NLSocket.hpp"

typedef void(^post_msg_block)(char *msg);

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (copy) post_msg_block postMsg;

@end





AppDelegate *di;

void set_appdelegate_bridge(AppDelegate *s)
{
    di = s;
}

NSString *bridge_msg_char(char *msg)
{
    return [[NSString alloc] initWithUTF8String:msg];
}

void post_msg_char(char *msg) {
    di.postMsg(msg);
}

static nlsdk::socket_server *server_instance()
{
    static nlsdk::socket_server *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = new nlsdk::socket_server();
        instance->set_post_msg_handle((void *)post_msg_char);
    });
    return instance;
}

