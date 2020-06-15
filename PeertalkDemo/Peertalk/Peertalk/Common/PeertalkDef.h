//
//  PeertalkDef.h
//  Peertalk
//
//  Created by mademao on 2020/6/10.
//  Copyright © 2020 mademao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Peertalk/PTChannel.h>

#pragma mark - Server Info

static const NSString *PTServerIPv4Address = @"127.0.0.1";
static const int PTServerIPv4PortNumber = 2345;

#pragma mark - PTMessageType

typedef NS_ENUM(NSUInteger, PTMessageType) {
    PTMessageTypeMinValue = 100,
    PTMessageTypeChangePort = 100,
    PTMessageTypeSetDirName = 101,
    PTMessageTypeText = 102,
    PTMessageTypeMaxValue = 102
};


#pragma mark - PTMessageTypeChangePort

typedef struct _PTMessageChangePort {
    int port;
} PTMessageChangePort;

extern dispatch_data_t PTMessageChangePort_dispatchDataWithPort(int port);

extern int PTMessageChangePort_portWithPayload(PTData *payload);


#pragma mark - PTMessageTypeSetDirName

typedef struct _PTMessageSetDirName {
    uint32_t length;
    uint8_t utf8_root_dir[0];
} PTMessageSetDirName;

extern dispatch_data_t PTMessageSetDirName_dispatchDataWithName(NSString *name);

extern NSString *PTMessagesetDirName_nameWithPayload(PTData *payload);


#pragma mark - PTMessageTypeText

typedef struct _PTMessageText {
    uint32_t length;
    uint8_t utf8text[0];
} PTMessageText;

extern dispatch_data_t PTMessageText_dispatchDataWithText(NSString *text);

extern NSString *PTMessageText_textWithPayload(PTData *payload);
