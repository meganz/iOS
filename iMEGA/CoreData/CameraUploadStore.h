
#import <Foundation/Foundation.h>
#import "MEGAStoreStack.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadStore : NSObject

@property (readonly) MEGAStoreStack *storeStack;

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
