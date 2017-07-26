
#import "MEGAAssetsPickerController.h"

#import "CTAssetsPickerController.h"

@interface MEGAAssetsPickerController : CTAssetsPickerController

- (instancetype)initToUploadToCloudDriveWithParentNode:(MEGANode *)parentNode;

@end
