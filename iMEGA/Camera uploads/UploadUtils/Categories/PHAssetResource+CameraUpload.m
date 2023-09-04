#import "PHAssetResource+CameraUpload.h"

@implementation PHAssetResource (CameraUpload)

- (unsigned long long)mnz_fileSize {
    unsigned long long size = 0;
    if ([self respondsToSelector:@selector(fileSize)]) {
        id resourceSize = [self valueForKey:@"fileSize"];
        if ([resourceSize respondsToSelector:@selector(unsignedLongLongValue)]) {
            size = [resourceSize unsignedLongLongValue];
        }
    }
    
    return size;
}

@end
