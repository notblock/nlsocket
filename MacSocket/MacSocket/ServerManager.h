//
//  ServerManager.h
//  MacSocket
//
//  Created by notblock on 2020/4/12.
//  Copyright © 2020 notblock. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LogString)(NSString *str);

typedef void(^ClientBlock)(int handle, NSString *msg);

@interface ServerManager : NSObject

@property (nonatomic, copy) LogString logString;

@property (nonatomic, copy) ClientBlock clientBlock;

- (int)start:(NSString *)ipAddress;

-(void)send:(int)client_socket msg:(NSString *)msg;

@end

NS_ASSUME_NONNULL_END
