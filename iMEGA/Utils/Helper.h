#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MEGASdk.h"

#define imagesSet       [[NSSet alloc] initWithObjects:@"gif", @"jpg", @"tif", @"jpeg", @"bmp", @"png",@"nef", nil]
#define videoSet        [[NSSet alloc] initWithObjects:/*@"mkv",*/ @"avi", @"mp4", @"m4v", @"mpg", @"mpeg", @"mov", @"3gp",/*@"aaf",*/ nil]

#define isImage(n)        [imagesSet containsObject:n]
#define isVideo(n)        [videoSet containsObject:n]

#define kMEGANode @"kMEGANode"
#define kIndex @"kIndex"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define megaRed      UIColorFromRGB(0xD90007)
#define megaBlack    UIColorFromRGB(0x212221)

#define megaInfoGrey UIColorFromRGB(0xF7F7F7)

#define megaDarkGray    [UIColor colorWithWhite:0.243 alpha:1.000]
#define megaLightGray   [UIColor colorWithWhite:0.933 alpha:1.000]

@interface Helper : NSObject

+ (NSString *)fileTypeIconForExtension:(NSString *)extension;

+ (UIImage *)imageForNode:(MEGANode *)node;

+ (UIImage *)genericImage;
+ (UIImage *)folderImage;
+ (UIImage *)folderSharedImage;

+ (NSString *)pathForOfflineDirectory:(NSString *)directory;

+ (NSString *)pathForOffline;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path;

+ (NSString *)pathForUser:(MEGAUser *)user searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

+ (void)downloadNodesOnFolder:(NSString *)folderPath parentNode:(MEGANode *)parentNode;

+ (void)logout;

@end
