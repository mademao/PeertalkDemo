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
    PTMessageTypePing = 100,
    PTMessageTypePong = 101,
    PTMessageTypeText = 102,
    PTMessageTypeMaxValue = 102
};


#pragma mark - PTMessageTypeText

typedef struct _PTMessageText {
    uint32_t length;
    uint8_t utf8text[0];
} PTMessageText;

extern dispatch_data_t PTMessageText_dispatchDataWithText(NSString *text);

extern NSString *PTMessageText_textWithPayload(PTData *payload);
