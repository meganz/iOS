
#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@class MEGABackgroundTaskOperation;

@protocol MEGABackgroundTaskOperationDelegate <NSObject>

- (void)backgroundTaskDidExpire;

@end

@interface MEGABackgroundTaskOperation : MEGAOperation

@property (weak, nonatomic) id<MEGABackgroundTaskOperationDelegate> backgroundTaskdelegate;

@end

NS_ASSUME_NONNULL_END
