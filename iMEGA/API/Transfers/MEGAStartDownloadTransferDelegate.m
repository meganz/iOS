
#import "MEGAStartDownloadTransferDelegate.h"

@interface MEGAStartDownloadTransferDelegate ()

@property (nonatomic, copy) void (^progress)(MEGATransfer *transfer);
@property (nonatomic, copy) void (^completion)(MEGATransfer *transfer);
@property (nonatomic, copy) void (^onError)(MEGAError *error);

@end

@implementation MEGAStartDownloadTransferDelegate

- (instancetype)initWithProgress:(void (^)(MEGATransfer *))progress completion:(void (^)(MEGATransfer *))completion onError:(void (^)(MEGAError *error))onError {
    if (self = [super init]) {
        _progress = progress;
        _completion = completion;
        _onError = onError;
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
        if (self.onError) {
            self.onError(error);
        }
        return;
    }
    
    if (self.completion) {
        self.completion(transfer);
    }
}

@end
