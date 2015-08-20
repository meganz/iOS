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
#define multimediaSet   [[NSSet alloc] initWithObjects:@"mp4", @"mov", @"mp3", @"3gp", @"wav", nil]
#define documentsSet    [[NSSet alloc] initWithObjects:@"pdf", @"rtf", @"csv", @"key", @"keynote", @"numbers", @"pages", @"doc", @"docx", @"dotx", @"wps", @"xls", @"xlsx", @"xlt", @"xltm", @"pps", @"ppt", @"pptx", nil]
#define openDocumentsSet [[NSSet alloc] initWithObjects:@"odb", @"odt", @"odm", @"ods", @"odg", @"odp", @"odf", @"odf", nil]

#define isImage(n)        [imagesSet containsObject:n.lowercaseString]
#define isVideo(n)        [videoSet containsObject:n.lowercaseString]
#define isMultimedia(n)   [multimediaSet containsObject:n.lowercaseString]
#define isDocument(n)     [documentsSet containsObject:n.lowercaseString]
#define isOpenDocument(n) [openDocumentsSet containsObject:n.lowercaseString]

#define kMEGANode @"kMEGANode"
#define kIndex @"kIndex"
#define kIsEraseAllLocalDataEnabled @"IsEraseAllLocalDataEnabled"

#define kLastUploadPhotoDate @"LastUploadPhotoDate"
#define kLastUploadVideoDate @"LastUploadVideoDate"
#define kCameraUploadsNodeHandle @"CameraUploadsNodeHandle"

#define kFont @"HelveticaNeue-Light"

#define megaOrange      [UIColor colorWithRed:1.0 green:165.0/255.0 blue:0.0 alpha:1.0]
#define megaPink        [UIColor colorWithRed:1.0 green:26.0/255.0 blue:83.0/255.0 alpha:1.0]
#define megaRed         [UIColor colorWithRed:217.0/255.0 green:0.0 blue:7.0/255.0 alpha:1.0]
#define megaGreen       [UIColor colorWithRed:49.0/255.0 green:181.0/255.0 blue:0.0 alpha:1.0]
#define megaBlue        [UIColor colorWithRed:43.0/255.0 green:166.0/255.0 blue:222.0/255.0 alpha:1.0]

#define megaInfoGray    [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:1.0]
#define megaGray        [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1.0]
#define megaMediumGray  [UIColor colorWithRed:119.0/255.0 green:119.0/255.0 blue:119.0/255.0 alpha:1.0]
#define megaDarkGray    [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0]

#define megaBlack       [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1.0]

#define megaLightGray   [UIColor colorWithWhite:0.933 alpha:1.000]

#pragma mark - Device

#define iPhone4X    ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 480)
#define iPhone5X    ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568)
#define iPhone6     ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 667)
#define iPhone6Plus ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 736)
#define iPad        ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

@interface Helper : NSObject

#pragma mark - Images

+ (NSString *)fileTypeIconForExtension:(NSString *)extension;

+ (UIImage *)imageForNode:(MEGANode *)node;
+ (UIImage *)imageForExtension:(NSString *)extension;

+ (UIImage *)infoImageForNode:(MEGANode *)node;
+ (UIImage *)infoImageForExtension:(NSString *)extension;

+ (UIImage *)genericImage;
+ (UIImage *)folderImage;
+ (UIImage *)folderSharedImage;
+ (UIImage *)defaultPhotoImage;

+ (UIImage *)downloadingArrowImage;
+ (UIImage *)downloadedArrowImage;
+ (UIImage *)downloadingTransferImage;
+ (UIImage *)uploadingTransferImage;
+ (UIImage *)downloadQueuedTransferImage;
+ (UIImage *)uploadQueuedTransferImage;

#pragma mark - Paths

+ (NSString *)pathForOfflineDirectory:(NSString *)directory;

+ (NSString *)pathForOffline;

+ (NSString *)pathRelativeToOfflineDirectory:(NSString *)totalPath;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path;

+ (NSString *)pathForUser:(MEGAUser *)user searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

#pragma mark - Utils for links when you are not logged

+ (MEGANode *)linkNode;
+ (void)setLinkNode:(MEGANode *)node;

+ (NSInteger)selectedOptionOnLink;
+ (void)setSelectedOptionOnLink:(NSInteger)option;

#pragma mark - Utils downloaded and downloading nodes

+ (NSMutableDictionary *)downloadingNodes;

+ (BOOL)isFreeSpaceEnoughToDownloadNode:(MEGANode *)node isFolderLink:(BOOL)isFolderLink;
+ (void)downloadNode:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink;

#pragma mark - Utils

+ (void)changeToViewController:(Class)classOfViewController onTabBarController:(UITabBarController *)tabBarController;
+ (unsigned long long)sizeOfFolderAtPath:(NSString *)path;

#pragma mark - Logout

+ (void)logout;
+ (void)logoutFromConfirmAccount;
+ (void)clearSession;
+ (void)deletePasscode;

@end
