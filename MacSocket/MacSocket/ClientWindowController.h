//
//  ClientWindowController.h
//  MacSocket
//
//  Created by notblock on 2020/5/11.
//  Copyright © 2020 notblock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClientWindowController : NSWindowController

- (void)msg_post:(NSString *)postMsg;

@end

NS_ASSUME_NONNULL_END
