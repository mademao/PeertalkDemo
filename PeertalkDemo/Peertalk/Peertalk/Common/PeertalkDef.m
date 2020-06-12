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
