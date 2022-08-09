#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataErrorHandler : NSObject

+ (void)abortAppWithError:(NSError *)error;
+ (BOOL)isSQLiteFullError:(NSError *)error;
+ (BOOL)hasSQLiteFullErrorInException:(NSException *)exception;

@end

NS_ASSUME_NONNULL_END
