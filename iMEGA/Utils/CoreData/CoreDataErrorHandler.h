#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataErrorHandler : NSObject

+ (void)exitAppWithError:(NSError *)error;
+ (BOOL)isSQLiteFullError:(NSError *)error;
+ (BOOL)isFileSystemFullError:(NSError *)error;
/// Whether the disk is too full to create files, which a store that fails to open often doesn't report as SQLITE_FULL
+ (BOOL)isDiskFull;
+ (BOOL)hasSQLiteFullErrorInException:(NSException *)exception;

@end

NS_ASSUME_NONNULL_END
