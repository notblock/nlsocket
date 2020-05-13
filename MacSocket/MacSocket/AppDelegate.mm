//
//  AppDelegate.m
//  MacSocket
//
//  Created by notblock on 2020/4/12.
//  Copyright © 2020 notblock. All rights reserved.
//

#import "AppDelegate.h"

#import "ClientWindowController.h"




@interface AppDelegate ()

//@property (nonatomic, strong) ServerManager *manager;

@property (weak) IBOutlet NSWindow *window;

@property (unsafe_unretained) IBOutlet NSTextView *logview;


@property (weak) IBOutlet NSTextField *sendValue;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    set_appdelegate_bridge(self);
    __weak typeof(self) wk = self;
    self.postMsg = ^(char *msg) {
        NSString *str = [[NSString alloc] initWithUTF8String:msg];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *temp = [NSString stringWithFormat:@"%@\nrev:%@", wk.logview.string, str];
            [wk.logview setString:temp];
        });
    };
    
}

- (void)showLogstr:(NSString *) str {
}

- (IBAction)start:(id)sender{
    server_instance()->server_start(12306, "0.0.0.0");
}

- (IBAction)send:(id)sender{
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (IBAction)openNewClient:(id)sender {
    ClientWindowController *client = [[ClientWindowController alloc] initWithWindowNibName:@"ClientWindowController"];
    
    [client.window makeMainWindow];
    [client.window orderFront:nil];
    [client.window center];
    
}


@end
