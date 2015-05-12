/**
 * @file MEGAHttpSession.m
 * @brief Handles client sessions for streaming purposes.
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

#import "MEGAHttpSession.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <TargetConditionals.h>
#import <AssertMacros.h>

NS_INLINE MEGARange MGAMakeRange(off_t location, off_t length) {
    return (MEGARange){location, length};
}

NS_INLINE BOOL MGALocationInRange(off_t loc, MEGARange range) {
    return (!(loc < range.location) && (loc - range.location) < range.length) ? YES : NO;
}

MEGARange MGAIntersectionRanges(MEGARange *range1, MEGARange *range2) {
    if (range1->length == 0 && range2->length != 0) {
        return *range2;
    }
    if (range2->length == 0 && range1->length != 0) {
        return *range1;
    }
    if (range1->length == 0 && range2->length == 0) {
        return MGAMakeRange(0, 0);
    }
    
    MEGARange a = range1->location < range2->location ? *range1 : *range2;
    MEGARange b = range1->location >= range2->location ? *range1 : *range2;
    
    if (a.location + a.length - 1 < b.location) {
        return MGAMakeRange(0, 0);
    }
    return MGAMakeRange(b.location, MIN(a.length - (b.location - a.location), b.length));
}

static void readStreamCallback(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo) {
    NSLog(@"Read stream callback for stream %@ with event %lu", stream, eventType);
    MEGAHttpSession *obj = (__bridge MEGAHttpSession *)clientCallBackInfo;
    [obj streamEventHasHappened:eventType];
}

static void writeStreamCallback(CFWriteStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo) {
    NSLog(@"Write stream callback for stream %@ with event %lu", stream, eventType);
    MEGAHttpSession *obj = (__bridge MEGAHttpSession *)clientCallBackInfo;
    [obj streamEventHasHappened:eventType];
}

@implementation MEGAHttpSession {
    CFHTTPMessageRef _request;
    CFReadStreamRef _readStream;
    CFWriteStreamRef _writeStream;
    NSUInteger _bytesWritten;
    NSMutableData *_dataToWrite;
    NSMutableData *_headerToWrite;
    BOOL closed;
}


- (id)initWithFd:(CFSocketNativeHandle)fd {

    self = [super init];
    if (!self) return nil;
    
    closed = FALSE;
    //_delegate = delegate;
    _dataToWrite = [[NSMutableData alloc] init];
    _request = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
    __Require_Action_Quiet(_request, fail, NSLog(@"Can't create empty request"));
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, fd, &_readStream, &_writeStream);
    __Require_Action_Quiet(_readStream, fail, NSLog(@"Can't create read stream"));
    __Require_Action_Quiet(_writeStream, fail, NSLog(@"Can't create write stream"));
    CFReadStreamSetProperty(_readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(_writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    const CFOptionFlags readStreamCallbacks = kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred;
    const CFOptionFlags writeStreamCallbacks = kCFStreamEventCanAcceptBytes | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred;
    CFStreamClientContext context = {0, (__bridge void *)self, (void *(*)(void *))CFRetain, (void (*)(void *))CFRelease, NULL};
    CFReadStreamSetClient(_readStream,
                          readStreamCallbacks,
                          readStreamCallback,
                          &context);
    CFReadStreamScheduleWithRunLoop(_readStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    __Require_Action_Quiet(CFReadStreamOpen(_readStream), fail, NSLog(@"Can't open read stream"));
    CFWriteStreamSetClient(_writeStream,
                           writeStreamCallbacks,
                           writeStreamCallback,
                           &context);
    CFWriteStreamScheduleWithRunLoop(_writeStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    __Require_Action_Quiet(CFWriteStreamOpen(_writeStream), fail, NSLog(@"Can't open write stream"));
    return self;
fail:
    if (_readStream) CFRelease(_readStream);
    if (_writeStream) CFRelease(_writeStream);
    _readStream = nil;
    _writeStream = nil;
    return nil;
}
- (void)haveData:(NSData *)data withOffset:(off_t)offset {

    if (!_writeStream) {
        NSLog(@"No valid write stream, ignoring data for %@: len: %@ offset: %lld", self, @(data.length), offset);
        return;
    }
    NSLog(@"%@: have data len: %@ offset: %lld", self, @(data.length), offset);
    MEGARange incomingRange = MGAMakeRange(offset, data.length);
    off_t requiredLocation = _range.location + _bytesWritten + _dataToWrite.length;
    if (!MGALocationInRange(requiredLocation, _range)) return; // we have all data, just need to write it
    MEGARange requiredRange = MGAMakeRange(requiredLocation, _range.length - (requiredLocation - _range.location));
    MEGARange intersectionRange = MGAIntersectionRanges(&requiredRange, &incomingRange);
    if (!intersectionRange.length) return; // not interested in this data
    unsigned char *bytes = (unsigned char *)data.bytes;
    bytes += intersectionRange.location - incomingRange.location;
    NSLog(@"%@: Will take len: %lld from offset: %lld", self, intersectionRange.length, intersectionRange.location - incomingRange.location);
    [_dataToWrite appendBytes:bytes length:(NSUInteger)intersectionRange.length];
    [self tryToWriteData];
}

- (void)streamEventHasHappened:(CFStreamEventType)eventType {

    switch (eventType) {
        case kCFStreamEventHasBytesAvailable:
            [self readStreamHasBytes];
            break;
        case kCFStreamEventCanAcceptBytes:
            [self tryToWriteData];
            break;
        case kCFStreamEventEndEncountered:
            [self streamEnded];
            break;
        case kCFStreamEventErrorOccurred: {
            [self streamError];
            break;
        }
        default:
            NSLog(@"Unknown sream event");
            break;
    }
}

- (void)closeStreams {
    if (_readStream && _writeStream) {
        closed = TRUE;
        //[_delegate connectionWasClosed:self];
    }
    [self cancel];
}

- (void)cancel {
    if (_readStream) {
        CFReadStreamUnscheduleFromRunLoop(_readStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(_readStream);
        _readStream = NULL;
    }
    if (_writeStream) {
        CFWriteStreamUnscheduleFromRunLoop(_writeStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(_writeStream);
        _writeStream = NULL;
    }
}


- (void)readStreamHasBytes {
    UInt8 buffer[4096];
    CFIndex readed = CFReadStreamRead(_readStream, buffer, sizeof(buffer));
    if (readed > 0) {
        CFHTTPMessageAppendBytes(_request, buffer, readed);
        if (CFHTTPMessageIsHeaderComplete(_request)) {
            CFHTTPMessageRef response = [self newResponseForRequest];
            NSLog(@"RESPONSE:\n%@", [[NSString alloc] initWithData:(__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(response)
                                                           encoding:NSUTF8StringEncoding]);
            NSData *data = (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(response);
            _headerToWrite = [[NSMutableData alloc] initWithData:data];
            [self tryToWriteData];
            CFRelease(response);
        }
    }
    else if (readed < 0) {
        NSLog(@"Error occurs on sream read");
        [self closeStreams];
    }
}

- (void)tryToWriteData {
    if (CFWriteStreamCanAcceptBytes(_writeStream) && (_headerToWrite.length || _dataToWrite.length)) {
        NSMutableData *data = _headerToWrite.length ? _headerToWrite : _dataToWrite;
        CFIndex written = CFWriteStreamWrite(_writeStream, data.bytes, data.length);
        if (written > 0) {
            [data replaceBytesInRange:NSMakeRange(0, written) withBytes:NULL length:0];
            if (data == _dataToWrite) {
                _bytesWritten += written;
            }
            else if (!_headerToWrite.length) {
                _headerToWrite = nil;
            }
        }
        else if (written < 0) {
            NSLog(@"Error occurs on sream write");
            [self closeStreams];
        }
    }
}

- (void)streamEnded {
    NSLog(@"Stream ended");
    [self closeStreams];
}

- (void)streamError {
    if (kCFStreamStatusError == CFReadStreamGetStatus(_readStream)) {
        NSLog(@"Read stream error: %@", (__bridge_transfer NSError *)CFReadStreamCopyError(_readStream));
    }
    if (kCFStreamStatusError == CFWriteStreamGetStatus(_writeStream)) {
        NSLog(@"Write stream error: %@", (__bridge_transfer NSError *)CFWriteStreamCopyError(_writeStream));
    }
    [self closeStreams];
}

static NSString * fileMIMEType(NSString *file) {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)file.pathExtension, NULL);
    NSString *mime = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    return mime;
}

static NSString * rfc1123CurrentDate(void) {
    static NSDateFormatter *df = nil;
    if(!df) {
        df = [NSDateFormatter new];
        df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
    }
    return [df stringFromDate:[NSDate date]];
}

- (CFHTTPMessageRef)newResponseForRequest {
    NSLog(@"REQUEST:\n%@", [[NSString alloc] initWithData:(__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(_request)
                                                  encoding:NSUTF8StringEncoding]);
    
    NSString *requestMethod = (__bridge_transfer NSString *)CFHTTPMessageCopyRequestMethod(_request);
    if (![@[@"HEAD", @"GET"] containsObject:requestMethod]) {
        NSLog(@"Got request with unsupported method: %@", requestMethod);
        return CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, kCFHTTPVersion1_0);
    }
    NSURL *url = (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL(_request);
    _handle = url.lastPathComponent.stringByDeletingPathExtension.longLongValue;
    
    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:_handle];
    if (!node) {
        NSLog(@"Can't find node for handle %lld", _handle);
        return CFHTTPMessageCreateResponse(kCFAllocatorDefault, 404, NULL, kCFHTTPVersion1_0);
    }
    NSString *rangeHeader = (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue(_request, CFSTR("Range"));
    if (rangeHeader) {
        NSString *bytesRange = [[rangeHeader componentsSeparatedByString:@"="] lastObject];
        NSArray *bytes = [bytesRange componentsSeparatedByString:@"-"];
        _range.location = (NSUInteger)[bytes[0] longLongValue];
        _range.length = (NSUInteger)[bytes[1] longLongValue] + 1 - _range.location;
    }
    else {
        _range = MGAMakeRange(0, node.size.longLongValue);
    }
    
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_0);
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Accept-Ranges"), CFSTR("bytes"));
    NSString *date = rfc1123CurrentDate();
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Date"), (__bridge CFStringRef)date);
    NSString *mime = fileMIMEType(node.name);
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), (__bridge CFStringRef)mime);
    NSString *contentRange = [[NSString alloc] initWithFormat:@"bytes %lld-%lld/%llu", _range.location, _range.location+_range.length-1, node.size.longLongValue];
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Range"), (__bridge CFStringRef)contentRange);
    NSString *contentLength = [[NSString alloc] initWithFormat:@"%lld", _range.length];
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (__bridge CFStringRef)contentLength);
    
    [[MEGASdkManager sharedMEGASdk] startStreamingNode:node startPos:[NSNumber numberWithLongLong:_range.location] size:[NSNumber numberWithLongLong:_range.length] delegate:self];

    return response;
}

- (BOOL)onTransferData:(MEGASdk *)api transfer:(MEGATransfer *)transfer buffer:(NSData *)buffer {

    if(closed == TRUE) {
        return NO;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(closed == TRUE) {
            return;
        }
        
        [self haveData:buffer withOffset:transfer.startPos.longLongValue + transfer.transferredBytes.longLongValue - transfer.deltaSize.longLongValue];
    });
    
    return YES;
}
@end
