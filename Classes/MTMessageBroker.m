// ------------------------------------------------------------------------------------
// Copyright (c) 2008, Drew McCormack
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
// 
// Redistributions of source code must retain the above copyright notice, 
// this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation and/or 
// other materials provided with the distribution.
// Neither the name of the MTMessage nor the names of its 
// contributors may be used to endorse or promote products derived from this software 
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.=======
// ------------------------------------------------------------------------------------

#import "MTMessageBroker.h"
#import "AsyncSocket.h"
#import "MTMessage.h"


static const unsigned int MessageHeaderSize = sizeof(UInt64);
static const float SocketTimeout = -1.0;


@implementation MTMessageBroker

-(id)initWithAsyncSocket:(AsyncSocket *)newSocket {
    if ( self = [super init] ) {
        if ( [newSocket canSafelySetDelegate] ) {
            socket = newSocket;
            [newSocket setDelegate:self];
            messageQueue = [NSMutableArray new];
            [socket readDataToLength:MessageHeaderSize withTimeout:SocketTimeout tag:0];
        }
        else {
            NSLog(@"Could not change delegate of socket");
            self = nil;
        }
    }
    return self;
}

-(id)delegate {
    return delegate;
}

-(void)setDelegate:(id)value {
    delegate = value;
}

-(AsyncSocket *)socket {
    return socket;
}

-(void)setIsPaused:(BOOL)yn {
    if ( yn != isPaused ) {
        isPaused = yn;
        if ( !isPaused ) {
            [socket readDataToLength:MessageHeaderSize withTimeout:SocketTimeout tag:(long)0];
        }
    }
}
            
-(BOOL)isPaused {
    return isPaused;
}


#pragma mark Sending/Receiving Messages
-(void)sendMessage:(MTMessage *)message {
    [messageQueue addObject:message];
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
    UInt64 header[1];
    header[0] = [messageData length]; 
    header[0] = CFSwapInt64HostToLittle(header[0]);  // Send header in little endian byte order
    [socket writeData:[NSData dataWithBytes:header length:MessageHeaderSize] withTimeout:SocketTimeout tag:(long)0];
    [socket writeData:messageData withTimeout:SocketTimeout tag:(long)1];
}


#pragma mark Socket Callbacks
-(void)onSocketDidDisconnect:(AsyncSocket *)sock {
    if ( connectionLostUnexpectedly ) {
        if ( delegate && [delegate respondsToSelector:@selector(messageBrokerDidDisconnectUnexpectedly:)] ) {
            [delegate messageBrokerDidDisconnectUnexpectedly:self];
        }
    }
}

-(void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    connectionLostUnexpectedly = YES;
}

-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if ( tag == 0 ) {
        // Header
        UInt64 header = *((UInt64*)[data bytes]);
        header = CFSwapInt64LittleToHost(header);  // Convert from little endian to native
        [socket readDataToLength:(CFIndex)header withTimeout:SocketTimeout tag:(long)1];
    }
    else if ( tag == 1 ) { 
        // Message body. Pass to delegate
        if ( delegate && [delegate respondsToSelector:@selector(messageBroker:didReceiveMessage:)] ) {
            MTMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [delegate messageBroker:self didReceiveMessage:message];
        }
        
        // Begin listening for next message
        if ( !isPaused ) [socket readDataToLength:MessageHeaderSize withTimeout:SocketTimeout tag:(long)0];
    }
    else {
        NSLog(@"Unknown tag in read of socket data %ld", tag);
    }
}

-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if ( tag == 1 ) {
        // If the message is now complete, remove from queue, and tell the delegate
        MTMessage *message = [messageQueue objectAtIndex:0];
        [messageQueue removeObjectAtIndex:0];
        if ( delegate && [delegate respondsToSelector:@selector(messageBroker:didSendMessage:)] ) {
            [delegate messageBroker:self didSendMessage:message];
        }
    }
}

@end
