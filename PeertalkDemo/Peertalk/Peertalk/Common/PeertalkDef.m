//
//  PeertalkDef.m
//  Peertalk
//
//  Created by mademao on 2020/6/10.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "PeertalkDef.h"

#pragma mark - PTMessageTypeChangePort

dispatch_data_t PTMessageChangePort_dispatchDataWithPort(int port) {
    PTMessageChangePort *messageChangePort = CFAllocatorAllocate(nil, sizeof(PTMessageChangePort), 0);
    messageChangePort->port = htonl(port);
    
    return dispatch_data_create((const void *)messageChangePort, sizeof(PTMessageChangePort), nil, ^{
        CFAllocatorDeallocate(nil, messageChangePort);
    });
}

int PTMessageChangePort_portWithPayload(PTData *payload) {
    PTMessageChangePort *messageChangePort = (PTMessageChangePort *)payload.data;
    messageChangePort->port = ntohl(messageChangePort->port);
    return messageChangePort->port;
}


#pragma mark - PTMessageTypeChangePort

dispatch_data_t PTMessageCreateDir_dispatchDataWithDirName(NSString *dirname) {
    const char *utf8name = [dirname cStringUsingEncoding:NSUTF8StringEncoding];
    size_t length = strlen(utf8name);
    PTMessageCreateDir *messageCreateDir = CFAllocatorAllocate(nil, sizeof(PTMessageCreateDir) + length, 0);
    memcpy(messageCreateDir->utf8_dir_name, utf8name, length);
    messageCreateDir->length = htonl(length);
    
    return dispatch_data_create((const void *)messageCreateDir, sizeof(PTMessageCreateDir) + length, nil, ^{
        CFAllocatorDeallocate(nil, messageCreateDir);
    });
}

NSString *PTMessageCreateDir_dirnameWithPayload(PTData *payload) {
    PTMessageCreateDir *messageCreateDir = (PTMessageCreateDir *)payload.data;
    messageCreateDir->length = ntohl(messageCreateDir->length);
    return [[NSString alloc] initWithBytes:messageCreateDir->utf8_dir_name length:messageCreateDir->length encoding:NSUTF8StringEncoding];
}


#pragma mark - PTMessageTypeFile

dispatch_data_t PTMessageFile_dispatchDataWithData(NSData *data, NSString *path) {
    const char *utf8path = [path cStringUsingEncoding:NSUTF8StringEncoding];
    size_t path_length = strlen(utf8path);
    
    size_t data_length = data.length;
    PTMessageFile *messageFile = CFAllocatorAllocate(nil, sizeof(PTMessageFile) + path_length + data_length, 0);
    memcpy(messageFile->utf8_path, utf8path, path_length);
    memcpy(messageFile->utf8_path + path_length, data.bytes, data_length);
    messageFile->path_length = htonl(path_length);
    messageFile->data_length = htonl(data_length);
    
    return dispatch_data_create((const void *)messageFile, sizeof(PTMessageFile) + path_length + data_length, nil, ^{
        CFAllocatorDeallocate(nil, messageFile);
    });
}

NSData *PTMessageFile_dataWithPayload(PTData *payload, NSString **path) {
    PTMessageFile *messageFile = (PTMessageFile *)payload.data;
    messageFile->path_length = ntohl(messageFile->path_length);
    messageFile->data_length = ntohl(messageFile->data_length);
    
    if (path) {
        *path = [[NSString alloc] initWithBytes:messageFile->utf8_path length:messageFile->path_length encoding:NSUTF8StringEncoding];
    }
    return [NSData dataWithBytes:messageFile->utf8_path + messageFile->path_length length:messageFile->data_length];
}


#pragma mark - PTMessageTypeText

dispatch_data_t PTMessageText_dispatchDataWithText(NSString *text) {
    const char *utf8text = [text cStringUsingEncoding:NSUTF8StringEncoding];
    size_t length = strlen(utf8text);
    PTMessageText *messageText = CFAllocatorAllocate(nil, sizeof(PTMessageText) + length, 0);
    memcpy(messageText->utf8text, utf8text, length);
    messageText->length = htonl(length);
    
    return dispatch_data_create((const void *)messageText, sizeof(PTMessageText) + length, nil, ^{
        CFAllocatorDeallocate(nil, messageText);
    });
}

NSString *PTMessageText_textWithPayload(PTData *payload) {
    PTMessageText *messageText = (PTMessageText *)payload.data;
    messageText->length = ntohl(messageText->length);
    return [[NSString alloc] initWithBytes:messageText->utf8text length:messageText->length encoding:NSUTF8StringEncoding];
}
