/**
 * @file MEGAHttpSession.h
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

#import <Foundation/Foundation.h>
#import "MEGASdkManager.h"

typedef struct {
    off_t location;
    off_t length;
} MEGARange;

@interface MEGAHttpSession : NSObject <MEGATransferDelegate>

@property (nonatomic, assign) MEGARange range;
@property (nonatomic, assign, readonly) UInt64 handle;
@property (nonatomic, assign) NSUInteger operationID;

- (id)initWithFd:(CFSocketNativeHandle)fd;
- (void)haveData:(NSData *)data withOffset:(off_t)offset;
- (void)cancel;

- (void)streamEventHasHappened:(CFStreamEventType)eventType;

@end
