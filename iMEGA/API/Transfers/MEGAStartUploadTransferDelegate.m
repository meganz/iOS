
#import "MEGAStartUploadTransferDelegate.h"

@interface MEGAStartUploadTransferDelegate ()

@property (nonatomic, getter=toUploadToChat) BOOL uploadToChat;

@property (nonatomic, copy) void (^transferProgress)(float transferProgress);

@property (nonatomic, copy) void (^completion)(uint64_t handle);

@end

@implementation MEGAStartUploadTransferDelegate

#pragma mark - Initialization

- (instancetype)initToUploadToChatWithTransferProgress:(void (^)(float transferProgress))transferProgress completion:(void (^)(uint64_t handle))completion {
    self = [super init];
    if (self) {
        _uploadToChat = YES;
        _transferProgress = transferProgress;
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (self.transferProgress) {
        float progress = transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue;
        if (progress > 0 && progress <= 1.0) {
            self.transferProgress(progress);
        }
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (error.type) return;
    
    if (self.completion) {
        self.completion(transfer.nodeHandle);
    }
}

@end
