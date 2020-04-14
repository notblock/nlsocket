//
//  ServerData.h
//  MacSocket
//
//  Created by null on 2020/4/13.
//  Copyright © 2020 notblock. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClientItem : NSObject

@property (nonatomic, strong) NSString *ip_address;
@property (nonatomic, assign) int handle;

@end





@interface ServerData : NSObject

+ (ServerData *)shareInstance;

- (NSDictionary *)userInfoDic;

- (void)setUserInfo:(NSDictionary *)userInfo;
@end

NS_ASSUME_NONNULL_END
