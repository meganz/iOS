
#import "MOAssetUploadFileNameRecord+CoreDataClass.h"

@implementation MOAssetUploadFileNameRecord

- (NSString *)description {
    return [NSString stringWithFormat:@"File name: %@, extension: %@, record: %@", self.localUniqueFileName, self.fileExtension, self.uploadRecord];
}

@end
