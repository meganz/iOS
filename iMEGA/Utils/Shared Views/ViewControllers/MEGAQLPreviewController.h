#import <QuickLook/QuickLook.h>

@interface MEGAQLPreviewController : QLPreviewController

- (instancetype)initWithFilePath:(NSString *)filePath;
- (instancetype)initWithArrayOfFiles:(NSArray *)files; 

@end
