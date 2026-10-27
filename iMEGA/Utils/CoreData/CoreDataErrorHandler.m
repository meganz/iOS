#import "CoreDataErrorHandler.h"
@import Firebase;
@import SQLite3;
@import CoreData;

@implementation CoreDataErrorHandler

+ (void)exitAppWithError:(NSError *)error {
    if (error.userInfo[NSSQLiteErrorDomain] != nil) {
        NSInteger sqliteErrorCode = [error.userInfo[NSSQLiteErrorDomain] integerValue];
        NSError *sqliteError = [NSError errorWithDomain:NSSQLiteErrorDomain code:sqliteErrorCode userInfo:nil];
        [[FIRCrashlytics crashlytics] logWithFormat:@"Aborting app due to CoreData error %@", sqliteError];
        [[FIRCrashlytics crashlytics] recordError:sqliteError];
    } else {
        [[FIRCrashlytics crashlytics] logWithFormat:@"Aborting app due to CoreData error %@", error];
        [[FIRCrashlytics crashlytics] recordError:error];
    }
    
    exit(0);
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

+ (BOOL)isDiskFull {
    // The opportunistic capacity drops to 0 before the disk is actually full, so anything above it means there is still room
    NSURL *homeURL = [NSURL fileURLWithPath:NSHomeDirectory()];
    NSNumber *opportunisticCapacity = [homeURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForOpportunisticUsageKey] error:nil][NSURLVolumeAvailableCapacityForOpportunisticUsageKey];
    if (opportunisticCapacity.longLongValue > 0) {
        return NO;
    }

    // The other capacities still count the system's reserve when the disk is full, so creating an empty directory confirms it:
    // it writes no data, yet fails with ENOSPC on a full disk. The fixed name leaves at most one empty directory behind.
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *probeURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"mega.ios.diskFullProbe"] isDirectory:YES];
    [fileManager removeItemAtURL:probeURL error:nil];
    NSError *error;
    BOOL created = [fileManager createDirectoryAtURL:probeURL withIntermediateDirectories:NO attributes:nil error:&error];
    [fileManager removeItemAtURL:probeURL error:nil];
    return !created && [self isFileSystemFullError:error];
}

+ (BOOL)isFileSystemFullError:(NSError *)error {
    if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
        return YES;
    }

    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    return [underlyingError.domain isEqualToString:NSPOSIXErrorDomain] && underlyingError.code == ENOSPC;
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
