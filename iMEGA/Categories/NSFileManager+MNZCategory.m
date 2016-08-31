
#import "NSFileManager+MNZCategory.h"

@implementation NSFileManager (MNZCategory)

- (NSString *)downloadsDirectory {
    NSString *downloadsDirectory = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Downloads"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadsDirectory]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:downloadsDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    return downloadsDirectory;
}

- (NSString *)uploadsDirectory {
    NSString *uploadsDirectory = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Uploads"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:uploadsDirectory]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:uploadsDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    return uploadsDirectory;
}

@end
