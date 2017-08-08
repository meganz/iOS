
#import "MEGAStartUploadTransferDelegate.h"

@interface MEGAStartUploadTransferDelegate : NSObject  <MEGATransferDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initToUploadToChatWithTotalBytes:(void (^)(long long totalBytes))totalBytes progress:(void (^)(float transferredBytes, float totalBytes))progress completion:(void (^)(long long totalBytes))completion;

@end
