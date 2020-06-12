//
//  ViewController.m
//  Peertalk-iOS
//
//  Created by mademao on 2020/6/10.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "ViewController.h"
#import <Peertalk/Peertalk.h>

@interface ViewController () <PTChannelDelegate>

@property (nonatomic, strong) UIButton *transferButton;

@property (nonatomic, strong) PTChannel *serverChannel;
@property (nonatomic, strong) PTChannel *clientChannel;
@property (nonatomic, assign) int currentPort;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.transferButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.transferButton.frame = CGRectMake(0, 0, 150, 50);
    self.transferButton.center = self.view.center;
    self.transferButton.layer.borderWidth = 1.0;
    [self.transferButton setTitle:@"发送文件" forState:UIControlStateNormal];
    [self.transferButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.transferButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.transferButton addTarget:self action:@selector(transferButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.transferButton];
}

- (void)transferButtonAction
{
    self.transferButton.enabled = NO;
    [self startServerChannelWithPort:PTServerIPv4PortNumber];
}

- (void)sendTransferBeginMessageIfNeeded
{
    if (self.currentPort == PTServerIPv4PortNumber) {
        return;
    }
    dispatch_data_t payload = PTMessageText_dispatchDataWithText(@"开始了啊");
    [self.clientChannel sendFrameOfType:PTMessageTypeText tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
        if (error) {
            [self sendTransferBeginMessageIfNeeded];
        } else {
            self.view.backgroundColor = [UIColor redColor];
        }
    }];
}

#pragma mark - server channel

- (void)startServerChannelWithPort:(in_port_t)port
{
    PeertalkProxy *proxy = [[PeertalkProxy alloc] initWithTarget:self];
    PTChannel *channel = [PTChannel channelWithDelegate:proxy];
    [channel listenOnPort:port IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
        if (error) {
            self.transferButton.enabled = YES;
        } else {
            self.serverChannel = channel;
            self.currentPort = port;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.clientChannel == nil) {
                    [self stopServerChannel];
                    [self stopClientChannel];
                    self.transferButton.enabled = YES;
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"请保证\n1.手机与Mac通过USB连接\n2.Mac端打开软件" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
                    [alertController addAction:action];
                    [self presentViewController:alertController animated:YES completion:nil];
                }
            });
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


#pragma mark - client channel

- (void)stopClientChannel
{
    if (self.clientChannel) {
        [self.clientChannel close];
        self.clientChannel = nil;
    }
}


#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel *)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize
{
    if (channel != self.clientChannel) {
        return NO;
    } else if (type < PTMessageTypeMinValue || type > PTMessageTypeMaxValue) {
        return NO;
    } else {
        return YES;
    }
}

- (void)ioFrameChannel:(PTChannel *)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload
{
    if (type == PTMessageTypeChangePort) {
        int port = PTMessageChangePort_portWithPayload(payload);
        [self stopClientChannel];
        [self stopServerChannel];
        [self startServerChannelWithPort:port];
    }
}

- (void)ioFrameChannel:(PTChannel *)channel didEndWithError:(NSError *)error
{
    if (channel == self.clientChannel) {
        [self stopClientChannel];
    }
}

- (void)ioFrameChannel:(PTChannel *)channel didAcceptConnection:(PTChannel *)otherChannel fromAddress:(PTAddress *)address
{
    [self stopClientChannel];
    
    self.clientChannel = otherChannel;
    self.clientChannel.userInfo = address;
    
    [self sendTransferBeginMessageIfNeeded];
}

@end
