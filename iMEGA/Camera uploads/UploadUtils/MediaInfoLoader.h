#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MediaInfoLoader : NSObject

@property (readonly) BOOL isMediaInfoLoaded;

- (void)loadMediaInfoWithTimeout:(NSTimeInterval)timeout completion:(void (^)(BOOL loaded))completion;

@end

NS_ASSUME_NONNULL_END
