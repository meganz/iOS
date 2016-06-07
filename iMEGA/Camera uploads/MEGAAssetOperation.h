/**
 * @file MEGAAssetOperation.h
 * @brief This class checks the action (Upload, copy, rename or ignore)
 * that should be taken on an asset and perform it
 *
 * (c) 2013-2016 by Mega Limited, Auckland, New Zealand
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
#import <Photos/Photos.h>

#import "MEGASdkManager.h"

@interface MEGAAssetOperation : NSOperation

- (instancetype)initWithPHAsset:(PHAsset *)asset parentNode:(MEGANode *)parentNode atomatically:(BOOL)automatically;
- (instancetype)initWithALAsset:(ALAsset *)asset cameraUploadNode:(MEGANode *)cameraUploadNode;

@end
