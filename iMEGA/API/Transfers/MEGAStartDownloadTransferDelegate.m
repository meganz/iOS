
#import "MEGAStartDownloadTransferDelegate.h"

@interface MEGAStartDownloadTransferDelegate ()

@property (nonatomic, copy) void (^completion)(MEGATransfer *transfer);

@end

@implementation MEGAStartDownloadTransferDelegate

- (instancetype)initWithCompletion:(void (^)(MEGATransfer *))completion {
    if (self = [super init]) {
        _completion = completion;
    }
    return self;
}

#pragma mark - MEGATransferDelegate

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (!error.type && self.completion) {
        self.completion(transfer);
    }
}

@end
