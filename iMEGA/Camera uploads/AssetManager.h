
#import <Foundation/Foundation.h>
#import "MOAssetUploadRecord+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface AssetManager : NSObject

+ (instancetype)shared;

- (void)startScanningWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
