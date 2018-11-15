
#import <Foundation/Foundation.h>
#import "MOAssetUploadRecord+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraScanner : NSObject

- (void)startScanningWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
