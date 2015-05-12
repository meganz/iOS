/**
 * @file MEGAProxyServer.m
 * @brief Common methods for streaming multimedia resources.
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */


#import "MEGAProxyServer.h"
#import "MEGAHttpSession.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <AssertMacros.h>
#import <TargetConditionals.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface MEGAProxyServer () {
    CFSocketRef _listeningSocket;
    NSMutableSet *_connectionHandlers;
}
@end

@implementation MEGAProxyServer

static MEGAProxyServer *_MEGAProxyServer = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _MEGAProxyServer = [[MEGAProxyServer alloc] init];
    });
    return _MEGAProxyServer;
}

- (BOOL)start {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    __Require_Action_Quiet(fd != -1, fail, NSLog(@"Failed to create socket"));
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len    = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port   = 0;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    int err = bind(fd, (const struct sockaddr *) &addr, sizeof(addr));
    __Require_Action_Quiet(err == 0, fail, NSLog(@"Failed to bind socket"));
    err = listen(fd, 10);
    __Require_Action_Quiet(err == 0, fail, NSLog(@"Failed to listen socket"));
    err = getsockname(fd, (struct sockaddr *) &addr, &(socklen_t){sizeof(addr)});
    __Require_Action_Quiet(err == 0, fail, NSLog(@"Failed to getsockname"));
    _port = ntohs(addr.sin_port);
    assert(_listeningSocket == NULL);
    _listeningSocket = CFSocketCreateWithNative(kCFAllocatorDefault,
                                                fd,
                                                kCFSocketAcceptCallBack,
                                                socketAcceptCallback,
                                                &(CFSocketContext){ 0, (__bridge void *) self, NULL, NULL, NULL });
    fd = -1; // CFSocket now ressponsible for native socket closing
    __Require_Action_Quiet(_listeningSocket, fail, NSLog(@"Failed to create CFSocket"));
    CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(NULL, _listeningSocket, 0);
    assert(rls != NULL);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRelease(rls);
    return YES;
fail:
    if (fd != -1) {
        close(fd);
    }
    if (_listeningSocket) {
        CFRelease(_listeningSocket);
    }
    return NO;
    
}

- (void)stop {
    if ( _listeningSocket != nil ) {
        CFSocketInvalidate(_listeningSocket);
        CFRelease(_listeningSocket);
        _listeningSocket = nil;
    }
}

// Called by CFSocket when someone connects to our listening socket.
// This implementation just bounces the request up to Objective-C.
static void socketAcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
#pragma unused(type)
    assert(type == kCFSocketAcceptCallBack);
#pragma unused(address)
    assert(data != NULL);
    MEGAProxyServer *obj = (__bridge MEGAProxyServer *)info;
    assert(obj != nil);
    assert(s == obj->_listeningSocket);
#pragma unused(s)
    [obj acceptConnection:*(CFSocketNativeHandle *)data];
}

- (BOOL)startServer {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    __Require_Action_Quiet(fd != -1, fail, NSLog(@"Failed to create socket"));
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len    = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port   = 0;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    int err = bind(fd, (const struct sockaddr *) &addr, sizeof(addr));
    __Require_Action_Quiet(err == 0, fail, NSLog(@"Failed to bind socket"));
    err = listen(fd, 10);
    __Require_Action_Quiet(err == 0, fail, NSLog(@"Failed to listen socket"));
    err = getsockname(fd, (struct sockaddr *) &addr, &(socklen_t){sizeof(addr)});
    __Require_Action_Quiet(err == 0, fail, NSLog(@"Failed to getsockname"));
    _port = ntohs(addr.sin_port);
    assert(_listeningSocket == NULL);
    _listeningSocket = CFSocketCreateWithNative(kCFAllocatorDefault,
                                                fd,
                                                kCFSocketAcceptCallBack,
                                                socketAcceptCallback,
                                                &(CFSocketContext){ 0, (__bridge void *) self, NULL, NULL, NULL });
    fd = -1; // CFSocket now ressponsible for native socket closing
    __Require_Action_Quiet(_listeningSocket, fail, NSLog(@"Failed to create CFSocket"));
    CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(NULL, _listeningSocket, 0);
    assert(rls != NULL);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRelease(rls);
    return YES;
fail:
    if (fd != -1) {
        close(fd);
    }
    if (_listeningSocket) {
        CFRelease(_listeningSocket);
    }
    return NO;
}

- (void)acceptConnection:(CFSocketNativeHandle)fd {
    NSLog(@"Accepting connection for fd: %d", fd);
    [_connectionHandlers addObject:[[MEGAHttpSession alloc] initWithFd:fd]];
}


@end
