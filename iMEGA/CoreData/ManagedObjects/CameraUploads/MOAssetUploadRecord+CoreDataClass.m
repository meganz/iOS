
#import "MOAssetUploadRecord+CoreDataClass.h"

@implementation MOAssetUploadRecord

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, %@, %@", self.localIdentifier, self.status, self.mediaType];
}

@end
