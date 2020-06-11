//
//  ViewController.m
//  Peertalk-iOS
//
//  Created by mademao on 2020/6/10.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "ViewController.h"
#import <Peertalk/Peertalk.h>

@interface ViewController ()

@property (nonatomic, strong) UIButton *transferButton;

@property (nonatomic, strong) PTChannel *connectChannel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.transferButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.transferButton.frame = CGRectMake(0, 0, 150, 50);
    self.transferButton.center = self.view.center;
    self.transferButton.layer.borderWidth = 1.0;
    [self.transferButton setTitle:@"发送文件" forState:UIControlStateNormal];
    [self.transferButton addTarget:self action:@selector(transferButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.transferButton];
}

- (void)transferButtonAction
{
    self.transferButton.enabled = NO;
    
    PeertalkProxy *proxy = [[PeertalkProxy alloc] initWithTarget:self];
    PTChannel *channel = [PTChannel channelWithDelegate:proxy];
    channel.userInfo = [NSString stringWithFormat:@"%@:%d", PTServerIPv4Address, PTServerIPv4PortNumber];
    [channel connectToPort:PTServerIPv4PortNumber IPv4Address:INADDR_LOOPBACK callback:^(NSError *error, PTAddress *address) {
        if (error) {
            self.transferButton.enabled = YES;
        } else {
            self.connectChannel = channel;
            self.connectChannel.userInfo = address;
        }
    }];
}


@end
