#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// Manager class to hook in the pre-exit process invoked by `exit()` call 
@interface AppExitHandlerManager: NSObject
- (void)registerExitHandler:(void (^)(void))completion;
@end

NS_ASSUME_NONNULL_END
