
#import "MOAssetUploadRecord+CameraUpload.h"
#import "CameraUploadRecordManager.h"
#import "NSString+MNZCategory.h"
#import "MOAssetUploadRecord+CoreDataClass.h"

static NSString * const CameraUploadLivePhotoExtension = @"live";

@implementation MOAssetUploadRecord (CameraUpload)

- (NSString *)mnz_localFileNameWithExtension:(NSString *)extension {
    NSString *originalFileName = [[NSString mnz_fileNameWithDate:self.creationDate] stringByAppendingPathExtension:extension];
    return [CameraUploadRecordManager.shared.fileNameCoordinator generateUniqueLocalFileNameForUploadRecord:self withOriginalFileName:originalFileName];
}

- (NSString *)mnz_localLivePhotoFileNameWithExtension:(NSString *)extension {
    NSString *originalFileName = [[[NSString mnz_fileNameWithDate:self.creationDate] stringByAppendingPathExtension:CameraUploadLivePhotoExtension] stringByAppendingPathExtension:extension];
    return [CameraUploadRecordManager.shared.fileNameCoordinator generateUniqueLocalFileNameForUploadRecord:self withOriginalFileName:originalFileName];
}

@end
