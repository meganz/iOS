
#import "MEGAStartDownloadTransferDelegate.h"

@interface MEGAStartDownloadTransferDelegate ()

@property (nonatomic, copy) void (^progress)(MEGATransfer *transfer);
@property (nonatomic, copy) void (^completion)(MEGATransfer *transfer);

@end

@implementation MEGAStartDownloadTransferDelegate

- (instancetype)initWithProgress:(void (^)(MEGATransfer *))progress completion:(void (^)(MEGATransfer *))completion {
    if (self = [super init]) {
        _progress = progress;
        _completion = completion;
    }
    return self;
}

#pragma mark - MEGATransferDelegate

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (self.progress) {
        self.progress(transfer);
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    if (self.completion) {
        self.completion(transfer);
    }
}

@end
