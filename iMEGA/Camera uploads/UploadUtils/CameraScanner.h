#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@class CameraScanner;

@protocol CameraScannerDelegate <NSObject>

- (void)cameraScanner:(CameraScanner *)scanner didObserveNewAssets:(NSArray<PHAsset *> *)assets;

@end

@interface CameraScanner : NSObject

- (instancetype)initWithDelegate:(id<CameraScannerDelegate>)delegate;

- (void)scanMediaTypes:(NSArray<NSNumber *> *)mediaTypes completion:(void (^ _Nullable)(NSError * _Nullable error))completion;

- (void)observePhotoLibraryChanges;
- (void)unobservePhotoLibraryChanges;

@end

NS_ASSUME_NONNULL_END
