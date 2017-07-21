
#import "MEGAStartUploadTransferDelegate.h"

@interface MEGAStartUploadTransferDelegate : NSObject  <MEGATransferDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initToUploadToChatWithTransferProgress:(void (^)(float transferProgress))transferProgress completion:(void (^)(uint64_t handle))completion;

@end
