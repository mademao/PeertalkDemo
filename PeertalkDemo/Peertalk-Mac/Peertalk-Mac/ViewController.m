//
//  ViewController.m
//  Peertalk-Mac
//
//  Created by mademao on 2020/6/10.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "ViewController.h"
#import <Peertalk/Peertalk.h>

@interface ConnectedDeviceItem : NSObject

@property (nonatomic, strong, readonly) NSNumber *deviceID;
@property (nonatomic, copy) NSDictionary *userInfo;
@property (nonatomic, assign) int transferPort;
@property (nonatomic, strong) PTChannel *channel;

@end

@implementation ConnectedDeviceItem

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo
{
    if (self = [super init]) {
        NSNumber *deviceID = [userInfo objectForKey:@"DeviceID"];
        if (deviceID == nil) {
            return nil;
        }
        self.deviceID = deviceID;
        self.userInfo = userInfo;
        self.transferPort = 0;
    }
    return self;
}

- (void)setDeviceID:(NSNumber *)deviceID
{
    _deviceID = deviceID;
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    } else if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    } else {
        return [((ConnectedDeviceItem *)object).deviceID integerValue] == [self.deviceID integerValue];
    }
}

- (NSUInteger)hash
{
    return [self.deviceID hash];
}

@end

@interface ViewController () <PTChannelDelegate>

@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (nonatomic, strong) NSMutableArray<ConnectedDeviceItem *> *connectedDeviceArray;

@property (nonatomic, strong) dispatch_queue_t connectUSBPortQueue;

@property (nonatomic, assign) int currentPort;

@property (nonatomic, strong) ConnectedDeviceItem *currentDeviceItem;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentPort = PTServerIPv4PortNumber + 1;
    
    [self registerNotification];
    
    PeertalkProxy *proxy = [PeertalkProxy proxyWithTarget:self];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [proxy performSelector:@selector(handleConnectedDevice)];
    }];
    [timer fire];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


#pragma mark - connected device array

- (void)addConnectedDeviceItemWithDict:(NSDictionary *)dict
{
    dispatch_async(self.connectUSBPortQueue, ^{
        ConnectedDeviceItem *item = [[ConnectedDeviceItem alloc] initWithUserInfo:dict];
        if (item) {
            NSInteger index = [self.connectedDeviceArray indexOfObject:item];
            if (index == NSNotFound) {
                [self.connectedDeviceArray addObject:item];
            } else {
                [self.connectedDeviceArray replaceObjectAtIndex:index withObject:item];
            }
        }
    });
}

- (void)removeConnectedDeviceItemWithDict:(NSDictionary *)dict
{
    dispatch_async(self.connectUSBPortQueue, ^{
        NSNumber *deviceID = [dict objectForKey:@"DeviceID"];
        if (deviceID == nil) {
            return;
        }
        
        for (int i = 0; i < self.connectedDeviceArray.count; i++) {
            ConnectedDeviceItem *item = [self.connectedDeviceArray objectAtIndex:i];
            if ([item.deviceID integerValue] == [deviceID integerValue]) {
                [self.connectedDeviceArray removeObjectAtIndex:i];
                if (item.channel) {
                    [item.channel close];
                    item.channel = nil;
                }
                break;
            }
        }
        
        if ([self.currentDeviceItem.deviceID integerValue] == [deviceID integerValue]) {
            if (self.currentDeviceItem.channel) {
                [self.currentDeviceItem.channel close];
                self.currentDeviceItem.channel = nil;
            }
            self.currentDeviceItem = nil;
        }
    });
}

- (void)setChannel:(PTChannel *)channel forDeviceItem:(ConnectedDeviceItem *)deviceItem shouldCurrentDeviceItem:(BOOL)shouldCurrentDeviceItem
{
    dispatch_async(self.connectUSBPortQueue, ^{
        deviceItem.channel = channel;
        if (shouldCurrentDeviceItem) {
            self.currentDeviceItem = deviceItem;
        }
    });
}

- (void)resetPortForDeviceItem:(ConnectedDeviceItem *)deviceItem
{
    dispatch_async(self.connectUSBPortQueue, ^{
        deviceItem.transferPort = 0;
    });
}

- (void)disconnectChannelForDeviceID:(NSNumber *)deviceID
{
    dispatch_async(self.connectUSBPortQueue, ^{
        for (int i = 0; i < self.connectedDeviceArray.count; i++) {
            ConnectedDeviceItem *item = [self.connectedDeviceArray objectAtIndex:i];
            if ([item.deviceID integerValue] == [deviceID integerValue]) {
                if (item.channel) {
                    [item.channel close];
                    item.channel = nil;
                }
                break;
            }
        }
        
        if ([self.currentDeviceItem.deviceID integerValue] == [deviceID integerValue]) {
            if (self.currentDeviceItem.channel) {
                [self.currentDeviceItem.channel close];
                self.currentDeviceItem.channel = nil;
            }
            self.currentDeviceItem = nil;
        }
    });
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

- (void)registerNotification
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserverForName:PTUSBDeviceDidAttachNotification object:[PTUSBHub sharedHub] queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self addConnectedDeviceItemWithDict:note.userInfo];
    }];
    
    [notificationCenter addObserverForName:PTUSBDeviceDidDetachNotification object:[PTUSBHub sharedHub] queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self removeConnectedDeviceItemWithDict:note.userInfo];
        [self appendSysOutputString:[NSString stringWithFormat:@"D%@ 与电脑USB连接断开", [note.userInfo objectForKey:@"DeviceID"]]];
    }];
}

- (void)handleConnectedDevice
{
    dispatch_async(self.connectUSBPortQueue, ^{
        for (int i = 0; i < self.connectedDeviceArray.count; i++) {
            ConnectedDeviceItem *item = [self.connectedDeviceArray objectAtIndex:i];
            if (item.transferPort == 0) {
                if (self.currentDeviceItem == nil) {
                    [self connectToUSBDeviceWithDeviceItem:item];
                } else if (self.currentDeviceItem == item) {
                    item.transferPort = self.currentPort++;
                    [self sendChangePortMessageToUSBDevice:item];
                }
            } else {
                if (item.channel == nil) {
                    [self connectToUSBDeviceWithDeviceItem:item];
                }
            }
        }
    });
}

- (void)connectToUSBDeviceWithDeviceItem:(ConnectedDeviceItem *)deviceItem
{
    PeertalkProxy *proxy = [PeertalkProxy proxyWithTarget:self];
    PTChannel *channel = [PTChannel channelWithDelegate:proxy];
    channel.userInfo = deviceItem.deviceID;
    
    int port = deviceItem.transferPort == 0 ? PTServerIPv4PortNumber : deviceItem.transferPort;
    [channel connectToPort:port overUSBHub:[PTUSBHub sharedHub] deviceID:deviceItem.deviceID callback:^(NSError *error) {
        if (error == nil) {
            [self setChannel:channel forDeviceItem:deviceItem shouldCurrentDeviceItem:port == PTServerIPv4PortNumber];
        } else {
            [self resetPortForDeviceItem:deviceItem];
        }
    }];
}

- (void)sendChangePortMessageToUSBDevice:(ConnectedDeviceItem *)deviceItem
{
    dispatch_data_t payload = PTMessageChangePort_dispatchDataWithPort(deviceItem.transferPort);
    [deviceItem.channel sendFrameOfType:PTMessageTypeChangePort tag:PTFrameNoTag withPayload:payload callback:nil];
}


#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel *)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize
{
    return YES;
}

- (void)ioFrameChannel:(PTChannel *)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload
{
    if (type == PTMessageTypeText) {
        NSString *messageText = PTMessageText_textWithPayload(payload);
        [self appendClientOutputString:messageText address:channel.userInfo];
    }
}

- (void)ioFrameChannel:(PTChannel *)channel didEndWithError:(NSError *)error
{
    [self disconnectChannelForDeviceID:channel.userInfo];
}


#pragma mark - lazy load

- (NSMutableArray<ConnectedDeviceItem *> *)connectedDeviceArray
{
    if (_connectedDeviceArray == nil) {
        _connectedDeviceArray = [NSMutableArray array];
    }
    return _connectedDeviceArray;
}

- (dispatch_queue_t)connectUSBPortQueue
{
    if (_connectUSBPortQueue == nil) {
        _connectUSBPortQueue = dispatch_queue_create("com.mademao.connect.usb.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _connectUSBPortQueue;
}

@end
