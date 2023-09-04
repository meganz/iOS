#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface AssetIdentifierInfo : NSObject

@property (strong, nonatomic, nullable) NSString *localIdentifier;
@property (nonatomic) PHAssetMediaSubtype mediaSubtype;

@end

NS_ASSUME_NONNULL_END
