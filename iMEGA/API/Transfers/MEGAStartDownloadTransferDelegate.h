#import <Foundation/Foundation.h>

@interface MEGAStartDownloadTransferDelegate : NSObject <MEGATransferDelegate>

- (id)init NS_UNAVAILABLE;
- (instancetype)initWithStart:(void (^)(MEGATransfer *))start progress:(void (^)(MEGATransfer *))progress completion:(void (^)(MEGATransfer *))completion onError:(void (^)(MEGATransfer *transfer, MEGAError *error))onError;
@end
