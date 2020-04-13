//
//  ServerData.h
//  MacSocket
//
//  Created by null on 2020/4/13.
//  Copyright © 2020 notblock. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ServerData : NSObject

+ (id)shareInstance;

- (NSMutableDictionary *)userInfos;

- (void)setUserInfo:(NSMutableDictionary *)userInfo;
@end

NS_ASSUME_NONNULL_END
