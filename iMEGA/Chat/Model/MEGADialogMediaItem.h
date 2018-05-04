
#import "JSQMediaItem.h"

#import "MEGAChatMessage.h"

@interface MEGADialogMediaItem : JSQMediaItem <JSQMessageMediaData, NSCoding, NSCopying>

@property (copy, nonatomic) MEGAChatMessage *message;

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message;

@end
