
#import <Foundation/Foundation.h>

extern NSString * const photoTransferSessionId;
extern NSString * const videoTransferSessionId;

NS_ASSUME_NONNULL_BEGIN

@interface TransferSessionManager : NSObject

+ (instancetype)shared;

@property (strong, nonatomic) NSURLSession *photoSession;
@property (strong, nonatomic) NSURLSession *videoSession;
@property (copy, nonatomic) void (^photoSessionCompletion)(void);
@property (copy, nonatomic) void (^videoSessionCompletion)(void);

- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session;
- (void)restorePhotoSessionIfNeeded;
- (void)restoreVideoSessionIfNeeded;

@end

NS_ASSUME_NONNULL_END
