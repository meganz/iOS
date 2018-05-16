
#import <Foundation/Foundation.h>

@interface MEGAStartDownloadTransferDelegate : NSObject <MEGATransferDelegate>

- (id)init NS_UNAVAILABLE;
- (instancetype)initWithProgress:(void (^)(MEGATransfer *))progress completion:(void (^)(MEGATransfer *))completion;

@end
