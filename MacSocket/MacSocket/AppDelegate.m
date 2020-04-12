//
//  AppDelegate.m
//  MacSocket
//
//  Created by notblock on 2020/4/12.
//  Copyright © 2020 notblock. All rights reserved.
//

#import "AppDelegate.h"

#import "ServerManager.h"

@interface AppDelegate ()

@property (nonatomic, strong) ServerManager *manager;

@property (weak) IBOutlet NSWindow *window;

@property (unsafe_unretained) IBOutlet NSTextView *logview;

@property (weak) IBOutlet NSTextField *ip_address;
@property (weak) IBOutlet NSTextField *sendValue;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self manager];
}

static int client_handle;

- (ServerManager *)manager {
    if (!_manager) {
        _manager = [[ServerManager alloc] init];
        __weak typeof(self) weakself = self;
        _manager.logString = ^(NSString * _Nonnull str) {
            [weakself showLogstr:str];
        };
        
        _manager.clientBlock = ^(int handle, NSString * _Nonnull msg) {
            client_handle = handle;
            [weakself showLogstr:msg];
        };
        
        
    }
    return _manager;
}


- (void)showLogstr:(NSString *) str {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.logview setString:[self.logview.string?:@"" stringByAppendingString:str]];
    });
}

- (IBAction)start:(id)sender{
    NSLog(@"server run: ip %@", self.ip_address.stringValue);
    [self.manager start:self.ip_address.stringValue];
}

- (IBAction)send:(id)sender{
    NSLog(@"server run: ip %@", self.ip_address.stringValue);
    [self.manager send:client_handle msg:self.sendValue.stringValue];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
