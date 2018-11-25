#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"

#define kIsCameraUploadsEnabled @"IsCameraUploadsEnabled"
#define kIsUploadVideosEnabled @"IsUploadVideosEnabled"
#define kIsUseCellularConnectionEnabled @"IsUseCellularConnectionEnabled"

@interface CameraUploads : NSObject <MEGATransferDelegate>

@property (nonatomic, strong) NSOperationQueue *assetsOperationQueue;

@property (nonatomic, assign) BOOL isCameraUploadsEnabled;
@property (nonatomic, assign) BOOL isUploadVideosEnabled;
@property (nonatomic, assign) BOOL isUseCellularConnectionEnabled;

@property (nonatomic, assign) BOOL shouldCameraUploadsBeDelayed;

@property (nonatomic, strong) NSDate *lastUploadPhotoDate;
@property (nonatomic, strong) NSDate *lastUploadVideoDate;

+ (CameraUploads *)syncManager;
- (void)resetOperationQueue;

@end
