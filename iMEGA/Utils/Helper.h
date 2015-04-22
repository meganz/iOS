/**
 * @file Helper.h
 * @brief Common methods for the app.
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

#import "MEGASdk.h"

#define imagesSet       [[NSSet alloc] initWithObjects:@"gif", @"jpg", @"tif", @"jpeg", @"bmp", @"png",@"nef", nil]
#define videoSet        [[NSSet alloc] initWithObjects:/*@"mkv",*/ @"avi", @"mp4", @"m4v", @"mpg", @"mpeg", @"mov", @"3gp",/*@"aaf",*/ nil]

#define isImage(n)        [imagesSet containsObject:n]
#define isVideo(n)        [videoSet containsObject:n]

#define kMEGANode @"kMEGANode"
#define kIndex @"kIndex"
#define kIsEraseAllLocalDataEnabled @"IsEraseAllLocalDataEnabled"
#define kRemainLoggedIn @"RemainLoggedIn"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define megaRed      UIColorFromRGB(0xD90007)
#define megaBlack    UIColorFromRGB(0x212221)

#define megaInfoGrey UIColorFromRGB(0xF7F7F7)

#define megaDarkGray    [UIColor colorWithWhite:0.243 alpha:1.000]
#define megaLightGray   [UIColor colorWithWhite:0.933 alpha:1.000]

@interface Helper : NSObject

#pragma mark - Images

+ (NSString *)fileTypeIconForExtension:(NSString *)extension;

+ (UIImage *)imageForNode:(MEGANode *)node;

+ (UIImage *)genericImage;
+ (UIImage *)folderImage;
+ (UIImage *)folderSharedImage;
+ (UIImage *)defaultPhotoImage;

+ (UIImage *)downloadingArrowImage;
+ (UIImage *)downloadedArrowImage;
+ (UIImage *)downloadTransferImage;
+ (UIImage *)uploadTransferImage;

#pragma mark - Paths

+ (NSString *)pathForOfflineDirectory:(NSString *)directory;

+ (NSString *)pathForOffline;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path;

+ (NSString *)pathForUser:(MEGAUser *)user searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

+ (NSString *)pathForPreviewDocument;
+ (void)setPathForPreviewDocument:(NSString *)path;
+ (NSString *)renamePathForPreviewDocument;
+ (void)setRenamePathForPreviewDocument:(NSString *)path;

#pragma mark - Utils for download and downloading nodes

+ (NSMutableDictionary *)downloadingNodes;
+ (NSMutableDictionary *)downloadedNodes;
+ (void)setDownloadedNodes;

+ (BOOL)isFreeSpaceEnoughToDownloadNode:(MEGANode *)node;
+ (void)downloadNode:(MEGANode *)node folder:(NSString *)folderPath folderLink:(BOOL)isFolderLink;
+ (void)downloadNodesOnFolder:(NSString *)folderPath parentNode:(MEGANode *)parentNode folderLink:(BOOL)isFolderLink;
+ (BOOL)createOfflineFolder:(NSString *)folderName folderPath:(NSString *)folderPath;

#pragma mark - Utils

+ (void)changeToViewController:(Class)classOfViewController onTabBarController:(UITabBarController *)tabBarController;
+ (unsigned long long)sizeOfFolderAtPath:(NSString *)path;

#pragma mark - Logout

+ (void)logout;
+ (void)clearSession;
+ (void)deletePasscode;

@end
