//
//  ServerData.m
//  MacSocket
//
//  Created by null on 2020/4/13.
//  Copyright © 2020 notblock. All rights reserved.
//

#import "ServerData.h"
@implementation ClientItem

@end
@implementation ServerData
{
    NSMutableDictionary *_userInfos;
    
    dispatch_queue_t serverdata_queue;
}
+ (ServerData *)shareInstance {
    static ServerData *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ServerData alloc] init];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        serverdata_queue = dispatch_queue_create("com.notblock.serverdata_queue", NULL);
        if (!_userInfos) {
            _userInfos = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (NSDictionary *)userInfoDic {
    return [_userInfos copy];
}

- (void)setUserInfo:(NSDictionary *)userInfo {
    dispatch_async(serverdata_queue, ^{
        [self->_userInfos addEntriesFromDictionary:userInfo];
    });
}

@end
