
#import "JSQPhotoMediaItem.h"
#import "MEGASdkManager.h"

@interface MEGAPhotoMediaItem : JSQPhotoMediaItem <MEGARequestDelegate>

@property (nonatomic, copy) MEGANode *node;

- (instancetype)initWithMEGANode:(MEGANode *)node;

@end
