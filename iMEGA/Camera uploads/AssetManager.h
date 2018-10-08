
#import <Foundation/Foundation.h>
#import "MOAssetUploadRecord+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface AssetManager : NSObject

+ (instancetype)shared;

- (void)startScanningWithCompletion:(void (^)(NSArray<MOAssetUploadRecord *> *))completion;

@end

NS_ASSUME_NONNULL_END
