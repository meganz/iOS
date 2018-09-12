
#import <Foundation/Foundation.h>

@class PHAsset, MOUploadTransfer;

@interface QueuedTransferItem : NSObject

@property (strong, nonatomic) PHAsset *asset;
@property (strong, nonatomic) MOUploadTransfer *uploadTransfer;

- (instancetype)initWithAsset:(PHAsset *)asset andUploadTransfer:(MOUploadTransfer *)uploadTransfer;

@end
