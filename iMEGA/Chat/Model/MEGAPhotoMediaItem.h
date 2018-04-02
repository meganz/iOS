
#import "JSQPhotoMediaItem.h"
#import "MEGASdkManager.h"

@interface MEGAPhotoMediaItem : JSQPhotoMediaItem

@property (nonatomic, copy) MEGANode *node;

- (instancetype)initWithMEGANode:(MEGANode *)node;

@end
