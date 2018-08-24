
#import "QueuedTransferItem.h"

@implementation QueuedTransferItem

- (instancetype)initWithAsset:(PHAsset *)asset andUploadTransfer:(MOUploadTransfer *)uploadTransfer {
    self = [super init];
    
    if (self) {
        _asset = asset;
        _uploadTransfer = uploadTransfer;
    }
    
    return self;
}

@end
