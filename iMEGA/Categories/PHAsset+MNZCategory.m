//
//  PHAsset+MNZCategory.m
//  MEGA
//
//  Created by Simon Wang on 11/10/18.
//  Copyright © 2018 MEGA. All rights reserved.
//

#import "PHAsset+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
@import Photos;

@implementation PHAsset (MNZCategory)

- (NSURL *)urlForCameraUploadWithExtension:(NSString *)extension {
    NSString *uploadFileName = [[NSString mnz_fileNameWithDate:self.creationDate] stringByAppendingPathExtension:extension];
    return [[[NSFileManager defaultManager] cameraUploadURL] URLByAppendingPathComponent:uploadFileName isDirectory:NO];
}

@end
