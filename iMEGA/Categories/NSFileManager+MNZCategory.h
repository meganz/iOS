
#import <Foundation/Foundation.h>

@interface NSFileManager (MNZCategory)

- (NSString *)downloadsDirectory;
- (NSString *)uploadsDirectory;
- (NSURL *)cameraUploadURL;

@end
