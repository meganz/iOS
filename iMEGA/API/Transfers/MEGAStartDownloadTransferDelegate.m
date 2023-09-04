#import "MEGAStartDownloadTransferDelegate.h"

@interface MEGAStartDownloadTransferDelegate ()

@property (nonatomic, copy) void (^start)(MEGATransfer *transfer);
@property (nonatomic, copy) void (^progress)(MEGATransfer *transfer);
@property (nonatomic, copy) void (^completion)(MEGATransfer *transfer);
@property (nonatomic, copy) void (^onError)(MEGATransfer *transfer, MEGAError *error);

@end

@implementation MEGAStartDownloadTransferDelegate

- (instancetype)initWithStart:(void (^)(MEGATransfer *))start progress:(void (^)(MEGATransfer *))progress completion:(void (^)(MEGATransfer *))completion onError:(void (^)(MEGATransfer *transfer, MEGAError *error))onError {
    if (self = [super init]) {
        _start = start;
        _progress = progress;
        _completion = completion;
        _onError = onError;
    }
    return self;
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (self.start) {
        self.start(transfer);
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (self.progress) {
        self.progress(transfer);
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (error.type) {
        if (self.onError) {
            self.onError(transfer ,error);
        }
        return;
    }
    
    if (self.completion) {
        self.completion(transfer);
    }
}

@end
