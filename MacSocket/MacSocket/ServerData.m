//
//  ServerData.m
//  MacSocket
//
//  Created by null on 2020/4/13.
//  Copyright © 2020 notblock. All rights reserved.
//

#import "ServerData.h"

@implementation ServerData
{
    NSMutableDictionary *_userInfos;
    
    dispatch_queue_t serverdata_queue;
}
+ (id)shareInstance {
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

- (NSMutableDictionary *)userInfos {
    return _userInfos;
}

- (void)setUserInfo:(NSMutableDictionary *)userInfo {
    dispatch_async(serverdata_queue, ^{
        [self.userInfos setObject:userInfo forKey:userInfo[@"oud"]];
    });
}

@end
