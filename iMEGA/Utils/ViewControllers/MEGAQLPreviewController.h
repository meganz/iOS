
#import <QuickLook/QuickLook.h>

@interface MEGAQLPreviewController : QLPreviewController

- (instancetype)initWithFilePath:(NSString *)filePath;
- (instancetype)initWithArrayOfFiles:(NSMutableArray *)files;

@end
