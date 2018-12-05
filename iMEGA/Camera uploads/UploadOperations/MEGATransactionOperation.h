
#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGATransactionOperation : MEGAOperation

@property (nonatomic, getter=didFinishWithError) BOOL finishedWithError;

@end

NS_ASSUME_NONNULL_END
