
#import "MOAssetUploadFileNameRecord+CoreDataClass.h"

@implementation MOAssetUploadFileNameRecord

- (NSString *)description {
    return [NSString stringWithFormat:@"File name: %@, extension: %@", self.localUniqueFileName, self.fileExtension];
}

@end
