#import "MEGAStartUploadTransferDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAStartUploadTransferDelegate : NSObject  <MEGATransferDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^ _Nullable)(MEGATransfer *transfer))completion;
- (instancetype)initToUploadToChatWithTotalBytes:(void (^ _Nullable)(MEGATransfer *transfer))totalBytes progress:(void (^ _Nullable)(MEGATransfer *transfer))progress completion:(void (^ _Nullable)(MEGATransfer *transfer))completion;

@end

NS_ASSUME_NONNULL_END
