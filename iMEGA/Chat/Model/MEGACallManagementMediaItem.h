
#import "JSQMediaItem.h"
#import "MEGAChatMessage.h"

@interface MEGACallManagementMediaItem : JSQMediaItem <JSQMessageMediaData, NSCoding, NSCopying>

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message;

@end
