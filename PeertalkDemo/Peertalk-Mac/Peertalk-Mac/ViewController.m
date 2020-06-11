//
//  ViewController.m
//  Peertalk-Mac
//
//  Created by mademao on 2020/6/10.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "ViewController.h"
#import <Peertalk/Peertalk.h>

@interface ViewController () <PTChannelDelegate>

@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (nonatomic, weak) PTChannel *serverChannel;
@property (nonatomic, strong) NSMutableArray<PTChannel *> *clientChannelArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.textView.editable = NO;

    [self startServerChannel];
}

- (void)dealloc
{
    [self stopServerChannel];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


#pragma mark - private methods

- (void)appendSysOutputString:(NSString *)string
{
    [self appendOutputString:[NSString stringWithFormat:@"[SYS] > %@", string]];
}

- (void)appendClientOutputString:(NSString *)string address:(NSString *)address
{
    [self appendOutputString:[NSString stringWithFormat:@"[%@] > %@", address, string]];
}

- (void)appendOutputString:(NSString *)string
{
    self.textView.string = [NSString stringWithFormat:@"%@\n%@", self.textView.string, string];
}

- (void)startServerChannel
{
    PeertalkProxy *proxy = [PeertalkProxy proxyWithTarget:self];
    PTChannel *channel = [PTChannel channelWithDelegate:proxy];
    [channel listenOnPort:PTServerIPv4PortNumber IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
        if (error) {
            [self appendSysOutputString:[NSString stringWithFormat:@"Fail start server channel : %@", error]];
        } else {
           [self appendSysOutputString:@"Success start server channel"];
        }
    }];
}

- (void)stopServerChannel
{
    if (self.serverChannel) {
        [self.serverChannel close];
        self.serverChannel = nil;
    }
}


#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel *)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize
{
    if ([self.clientChannelArray containsObject:channel] == NO) {
        return NO;
    } else if (type < PTMessageTypeMinValue || type > PTMessageTypeMaxValue) {
        return NO;
    } else {
        return YES;
    }
}

- (void)ioFrameChannel:(PTChannel *)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload
{
    if (type == PTMessageTypeText) {
        NSString *textString = PTMessageText_textWithPayload(payload);
        [self appendClientOutputString:textString address:channel.userInfo];
    }
}

- (void)ioFrameChannel:(PTChannel *)channel didEndWithError:(NSError *)error
{
    if (error) {
        [self appendSysOutputString:[NSString stringWithFormat:@"%@ disconnect with error: %@", channel.userInfo, error]];
    } else {
        [self appendSysOutputString:[NSString stringWithFormat:@"%@ disconnect", channel.userInfo]];
    }
    
    if ([self.clientChannelArray containsObject:channel]) {
        [self.clientChannelArray removeObject:channel];
    }
}

- (void)ioFrameChannel:(PTChannel *)channel didAcceptConnection:(PTChannel *)otherChannel fromAddress:(PTAddress *)address
{
    if ([self.clientChannelArray containsObject:otherChannel] == NO) {
        [self.clientChannelArray addObject:otherChannel];
    }
    
    otherChannel.userInfo = address;
    
    [self appendSysOutputString:[NSString stringWithFormat:@"accept connection from %@", address]];
}


#pragma mark - lazy load

- (NSMutableArray<PTChannel *> *)clientChannelArray
{
    if (_clientChannelArray == nil) {
        _clientChannelArray = [NSMutableArray array];
    }
    return _clientChannelArray;
}

@end
