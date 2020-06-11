//
//  ViewController.m
//  Peertalk-Mac
//
//  Created by mademao on 2020/6/10.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "ViewController.h"
#import <Peertalk/Peertalk.h>

typedef NS_ENUM(NSUInteger, TextViewStringType) {
    TextViewStringTypeSys
};

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

- (void)appendOutputString:(NSString *)string stringType:(TextViewStringType)stringType
{
    NSString *preString = nil;
    switch (stringType) {
        case TextViewStringTypeSys:
            preString = @"[SYS] > ";
            break;
        default:
            preString = @"> ";
            break;
    }
    self.textView.string = [NSString stringWithFormat:@"%@%@%@\n", self.textView.string, preString, string];
}

- (void)startServerChannel
{
    PeertalkProxy *proxy = [PeertalkProxy proxyWithTarget:self];
    PTChannel *channel = [PTChannel channelWithDelegate:proxy];
    [channel listenOnPort:PTServerIPv4PortNumber IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
        if (error) {
            [self appendOutputString:[NSString stringWithFormat:@"Fail start server channel : %@", error] stringType:TextViewStringTypeSys];
        } else {
           [self appendOutputString:@"Success start server channel" stringType:TextViewStringTypeSys];
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
//        [self appendOutputString:[NSString stringWithFormat:@"[]] stringType:<#(TextViewStringType)#>]
    }
}

//- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload
//{
//
//}
//
//@optional
//// Invoked to accept an incoming frame on a channel. Reply NO ignore the
//// incoming frame. If not implemented by the delegate, all frames are accepted.
//
//
//// Invoked when the channel closed. If it closed because of an error, *error* is
//// a non-nil NSError object.
//- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error;
//
//// For listening channels, this method is invoked when a new connection has been
//// accepted.
//- (void)ioFrameChannel:(PTChannel*)channel didAcceptConnection:(PTChannel*)otherChannel fromAddress:(PTAddress*)address;


#pragma mark - lazy load

- (NSMutableArray<PTChannel *> *)clientChannelArray
{
    if (_clientChannelArray == nil) {
        _clientChannelArray = [NSMutableArray array];
    }
    return _clientChannelArray;
}

@end
