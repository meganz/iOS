
#import "MEGAStartUploadTransferDelegate.h"

@interface MEGAStartUploadTransferDelegate ()

@property (nonatomic, getter=toUploadToChat) BOOL uploadToChat;

@property (nonatomic, copy) void (^totalBytes)(long long totalBytes);
@property (nonatomic, copy) void (^progress)(float transferredBytes, float totalBytes);
@property (nonatomic, copy) void (^completion)(long long transferTotalBytes);

@end

@implementation MEGAStartUploadTransferDelegate

#pragma mark - Initialization

- (instancetype)initToUploadToChatWithTotalBytes:(void (^)(long long totalBytes))totalBytes progress:(void (^)(float transferredBytes, float totalBytes))progress completion:(void (^)(long long totalBytes))completion {
    self = [super init];
    if (self) {
        _uploadToChat = YES;
        _totalBytes = totalBytes;
        _progress = progress;
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    if (self.totalBytes) {
        self.totalBytes(transfer.totalBytes.longLongValue);
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (self.progress) {
         self.progress(transfer.transferredBytes.floatValue, transfer.totalBytes.floatValue);
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (self.completion) {
        self.completion(transfer.totalBytes.longLongValue);
    }
    
    if (error.type) return;
}

@end
