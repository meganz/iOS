//
//  PHAsset+MNZCategory.h
//  MEGA
//
//  Created by Simon Wang on 11/10/18.
//  Copyright © 2018 MEGA. All rights reserved.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (MNZCategory)

- (NSURL *)urlForCameraUploadWithExtension:(NSString *)extension;

@end

NS_ASSUME_NONNULL_END
