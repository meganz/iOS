#import "MEGAStartUploadTransferDelegate.h"

@interface MEGAStartUploadTransferDelegate ()

@property (nonatomic, copy) void (^totalBytes)(MEGATransfer *transfer);
@property (nonatomic, copy) void (^progress)(MEGATransfer *transfer);
@property (nonatomic, copy) void (^completion)(MEGATransfer *transfer);

@end

@implementation MEGAStartUploadTransferDelegate

#pragma mark - Initialization

- (instancetype)initWithCompletion:(void (^)(MEGATransfer *transfer))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

- (instancetype)initToUploadToChatWithTotalBytes:(void (^)(MEGATransfer *transfer))totalBytes progress:(void (^)(MEGATransfer *transfer))progress completion:(void (^)(MEGATransfer *transfer))completion {
    self = [super init];
    if (self) {
        _totalBytes = totalBytes;
        _progress = progress;
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (self.totalBytes) {
        self.totalBytes(transfer);
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (self.progress) {
         self.progress(transfer);
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {    
    if (self.completion) {
        self.completion(transfer);
    }
    
    if (error.type) return;
}

@end
