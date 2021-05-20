#import "CoreDataErrorHandler.h"
@import Firebase;
@import SQLite3;
@import CoreData;

@implementation CoreDataErrorHandler

+ (void)abortAppWithError:(NSError *)error {
    if (error.userInfo[NSSQLiteErrorDomain] != nil) {
        NSInteger sqliteErrorCode = [error.userInfo[NSSQLiteErrorDomain] integerValue];
        NSError *sqliteError = [NSError errorWithDomain:NSSQLiteErrorDomain code:sqliteErrorCode userInfo:nil];
        [[FIRCrashlytics crashlytics] recordError:sqliteError];
    } else {
        [[FIRCrashlytics crashlytics] recordError:error];
    }
    
    abort();
}

+ (BOOL)isSQLiteFullError:(NSError *)error {
    if ([error.domain isEqualToString:NSSQLiteErrorDomain] && error.code == SQLITE_FULL) {
        return YES;
    }
    
    if ([error.userInfo[NSSQLiteErrorDomain] integerValue] == SQLITE_FULL) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)hasSQLiteFullErrorInException:(NSException *)exception {
    if ([exception.userInfo[@"UserInfo"][@"NSSQLiteErrorDomain"] integerValue] == SQLITE_FULL) {
        return YES;
    } else if ([exception.reason containsString:@"NSSQLiteErrorDomain=13"]) {
        return YES;
    } else {
        return NO;
    }
}

@end
