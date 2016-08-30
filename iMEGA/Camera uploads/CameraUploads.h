/**
 * @file CameraUploads.h
 * @brief Uploads assets from device to your mega account
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"

#define kIsCameraUploadsEnabled @"IsCameraUploadsEnabled"
#define kIsUploadVideosEnabled @"IsUploadVideosEnabled"
#define kIsUseCellularConnectionEnabled @"IsUseCellularConnectionEnabled"
#define kIsOnlyWhenChargingEnabled @"IsOnlyWhenChargingEnabled"

@interface CameraUploads : NSObject <MEGARequestDelegate, MEGATransferDelegate>

@property (nonatomic, strong) NSOperationQueue *assetsOperationQueue;

@property (nonatomic, weak) UITabBarController *tabBarController;

@property (nonatomic, assign) BOOL isCameraUploadsEnabled;
@property (nonatomic, assign) BOOL isUploadVideosEnabled;
@property (nonatomic, assign) BOOL isUseCellularConnectionEnabled;
@property (nonatomic, assign) BOOL isOnlyWhenChargingEnabled;

@property (nonatomic, strong) NSDate *lastUploadPhotoDate;
@property (nonatomic, strong) NSDate *lastUploadVideoDate;

+ (CameraUploads *)syncManager;
- (void)resetOperationQueue;
- (void)setBadgeValue:(NSString *)value;

@end
