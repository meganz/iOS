
#import <Foundation/Foundation.h>

@interface MEGAStartDownloadTransferDelegate : NSObject <MEGATransferDelegate>

- (id)init NS_UNAVAILABLE;
- (instancetype)initWithCompletion:(void (^)(MEGATransfer *transfer))completion;

@end
