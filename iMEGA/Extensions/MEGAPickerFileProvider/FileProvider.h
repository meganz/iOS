
#import "MEGARequestDelegate.h"
#import "MEGATransferDelegate.h"

@interface FileProvider : NSFileProviderExtension <MEGATransferDelegate, MEGARequestDelegate>

@property (nonatomic) MEGANode *oldNode;
@property (nonatomic) NSURL *url;
@property (nonatomic) dispatch_semaphore_t semaphore;

@end
