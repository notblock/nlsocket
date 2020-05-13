//
//  ClientWindowController.m
//  MacSocket
//
//  Created by notblock on 2020/5/11.
//  Copyright © 2020 notblock. All rights reserved.
//

#import "ClientWindowController.h"
#include "NLSocket.hpp"


static ClientWindowController *chandle;
static nlsdk::socket_client *instance;

void post_msg(char *msg)
{
    NSString *msgstr = [NSString stringWithUTF8String:msg];
    [chandle msg_post:msgstr];
}

static inline void init_socket()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = new nlsdk::socket_client();
        instance->set_post_msg_handle((void *)post_msg);
    });
}


@interface ClientWindowController ()
@property (weak) IBOutlet NSButton *connectBtn;
@property (weak) IBOutlet NSTextField *inputText;
@property (unsafe_unretained) IBOutlet NSTextView *msgValue;


@property (weak) IBOutlet NSTableView *contactTable;

@property (weak) IBOutlet NSButton *sendBtn;
@end

@implementation ClientWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [_sendBtn setEnabled:NO];
    init_socket();
    chandle = self;
    
}

- (void)msg_post:(NSString *)postMsg {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *allMsg = [_msgValue.string stringByAppendingFormat:@"\nrcv:%@", postMsg];
        [self.msgValue setString:allMsg];
    });
}


- (IBAction)sendClick:(id)sender {
    instance->send_msg(_inputText.stringValue.UTF8String);
}

- (IBAction)connectClick:(id)sender {
    int result = instance->client_start(12306, "127.0.0.1");
    if (result == 0) {
        [self msg_post:@"已连接上服务器"];
        [_sendBtn setEnabled:YES];
        [_connectBtn setEnabled:NO];
    }
    
}

@end
