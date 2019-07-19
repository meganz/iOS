
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BackgroundRefreshPerformer : NSObject

- (void)performBackgroundRefreshWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completion;

@end

NS_ASSUME_NONNULL_END
