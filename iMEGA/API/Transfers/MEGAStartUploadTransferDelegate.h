#import "MEGAStartUploadTransferDelegate.h"

@interface MEGAStartUploadTransferDelegate : NSObject  <MEGATransferDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGATransfer *transfer))completion;
- (instancetype)initToUploadToChatWithTotalBytes:(void (^)(MEGATransfer *transfer))totalBytes progress:(void (^)(MEGATransfer *transfer))progress completion:(void (^)(MEGATransfer *transfer))completion;

@end
