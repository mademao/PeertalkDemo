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
    PTMessageTypeCreateDir = 101,
    PTMessageTypeFile = 102,
    PTMessageTypeText = 103,
    PTMessageTypeMaxValue = 103
};


#pragma mark - PTMessageTypeChangePort

typedef struct _PTMessageChangePort {
    int port;
} PTMessageChangePort;

extern dispatch_data_t PTMessageChangePort_dispatchDataWithPort(int port);

extern int PTMessageChangePort_portWithPayload(PTData *payload);


#pragma mark - PTMessageTypeCreateDir

typedef struct _PTMessageCreateDir {
    uint32_t length;
    uint8_t utf8_dir_name[0];
} PTMessageCreateDir;

extern dispatch_data_t PTMessageCreateDir_dispatchDataWithDirName(NSString *dirname);

extern NSString *PTMessageCreateDir_dirnameWithPayload(PTData *payload);


#pragma mark - PTMessageTypeFile

typedef struct _PTMessageFile {
    uint32_t path_length;
    uint32_t data_length;
    uint8_t utf8_path[0];
    uint8_t data[0];
} PTMessageFile;

extern dispatch_data_t PTMessageFile_dispatchDataWithData(NSData *data, NSString *path);

extern NSData *PTMessageFile_dataWithPayload(PTData *payload, NSString **path);


#pragma mark - PTMessageTypeText

typedef struct _PTMessageText {
    uint32_t length;
    uint8_t utf8text[0];
} PTMessageText;

extern dispatch_data_t PTMessageText_dispatchDataWithText(NSString *text);

extern NSString *PTMessageText_textWithPayload(PTData *payload);
