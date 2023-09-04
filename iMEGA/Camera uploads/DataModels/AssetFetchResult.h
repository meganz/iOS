#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface AssetFetchResult : NSObject

@property (strong, nonatomic) NSArray<NSNumber *> *mediaTypes;
@property (strong, nonatomic) PHFetchResult<PHAsset *> *fetchResult;

- (instancetype)initWithMediaTypes:(NSArray<NSNumber *> *)mediaTypes fetchResult:(PHFetchResult<PHAsset *> *)fetchResult;

- (BOOL)isContainedByAssetFetchResult:(AssetFetchResult *)result;

@end

NS_ASSUME_NONNULL_END
