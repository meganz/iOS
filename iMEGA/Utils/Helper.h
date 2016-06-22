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
#define videoSet        [[NSSet alloc] initWithObjects:@"mp4", @"mov", @"m4v", @"3gp", /*@"mkv", @"avi", @"mpg", @"mpeg",@"aaf",*/ nil]
#define multimediaSet   [[NSSet alloc] initWithObjects:@"mp4", @"mov", @"3gp", @"wav", @"m4v", @"m4a", @"mp3", nil]

#define isImage(n)        [imagesSet containsObject:n.lowercaseString]
#define isVideo(n)        [videoSet containsObject:n.lowercaseString]
#define isMultimedia(n)   [multimediaSet containsObject:n.lowercaseString]

#define kMEGANode @"kMEGANode"
#define kIndex @"kIndex"
#define kPath @"kPath"
#define kIsEraseAllLocalDataEnabled @"IsEraseAllLocalDataEnabled"

#define kLastUploadPhotoDate @"LastUploadPhotoDate"
#define kLastUploadVideoDate @"LastUploadVideoDate"
#define kCameraUploadsNodeHandle @"CameraUploadsNodeHandle"

#define kFont @"SFUIText-Light"

typedef NS_OPTIONS(NSUInteger, NodesAre) {
    NodesAreFiles    = 1 << 0,
    NodesAreFolders  = 1 << 1,
    NodesAreExported = 1 << 2
};

@interface Helper : NSObject

#pragma mark - Languages

+ (BOOL)isLanguageSupported:(NSString *)languageID;
+ (NSString *)languageID:(NSUInteger)index;

#pragma mark - Images

+ (NSString *)fileTypeIconForExtension:(NSString *)extension;

+ (UIImage *)imageForNode:(MEGANode *)node;
+ (UIImage *)imageForExtension:(NSString *)extension;

+ (UIImage *)infoImageForNode:(MEGANode *)node;
+ (UIImage *)infoImageForExtension:(NSString *)extension;

+ (UIImage *)genericImage;
+ (UIImage *)folderImage;
+ (UIImage *)folderSharedImage;
+ (UIImage *)incomingFolderImage;
+ (UIImage *)outgoingFolderImage;
+ (UIImage *)defaultPhotoImage;

+ (UIImage *)downloadedArrowImage;
+ (UIImage *)downloadingTransferImage;
+ (UIImage *)uploadingTransferImage;
+ (UIImage *)downloadQueuedTransferImage;
+ (UIImage *)uploadQueuedTransferImage;

#pragma mark - Paths

+ (NSString *)pathForOffline;

+ (NSString *)pathRelativeToOfflineDirectory:(NSString *)totalPath;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path;

+ (NSString *)pathForUser:(MEGAUser *)user searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

#pragma mark - Utils for links when you are not logged

+ (MEGANode *)linkNode;
+ (void)setLinkNode:(MEGANode *)node;
+ (NSMutableArray *)nodesFromLinkMutableArray;

+ (NSInteger)selectedOptionOnLink;
+ (void)setSelectedOptionOnLink:(NSInteger)option;

#pragma mark - Utils downloaded and downloading nodes

+ (NSMutableDictionary *)downloadingNodes;

+ (BOOL)isFreeSpaceEnoughToDownloadNode:(MEGANode *)node isFolderLink:(BOOL)isFolderLink;
+ (void)downloadNode:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink;

#pragma mark - Utils

+ (void)changeToViewController:(Class)classOfViewController onTabBarController:(UITabBarController *)tabBarController;
+ (unsigned long long)sizeOfFolderAtPath:(NSString *)path;
+ (uint64_t)freeDiskSpace;

#pragma mark - Utils for nodes

+ (void)thumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell;
+ (void)setThumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell;

+ (NSString *)sizeAndDateForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)filesAndFoldersInFolderNode:(MEGANode *)node api:(MEGASdk *)api;

+ (UIActivityViewController *)activityViewControllerForNodes:(NSArray *)nodesArray button:(UIBarButtonItem *)shareBarButtonItem;
+ (NSUInteger)totalOperations;
+ (void)setCopyToPasteboard:(BOOL)boolValue;
+ (BOOL)copyToPasteboard;

#pragma mark - Utils for empty states

+ (UIEdgeInsets)capInsetsForEmptyStateButton;
+ (UIEdgeInsets)rectInsetsForEmptyStateButton;

#pragma mark - Logout

+ (void)logout;
+ (void)logoutFromConfirmAccount;
+ (void)clearSession;
+ (void)deletePasscode;

#pragma mark - Log

+ (UIAlertView *)logAlertView:(BOOL)enableLog;
+ (void)enableLog:(BOOL)enableLog;

@end
