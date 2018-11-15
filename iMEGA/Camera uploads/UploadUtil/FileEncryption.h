
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MEGABackgroundMediaUpload;

@interface FileEncryption : NSObject

- (instancetype)initWithMediaUpload:(MEGABackgroundMediaUpload *)mediaUpload outputFileURL:(NSURL *)outputFileURL;

- (void)encryptFileAtURL:(NSURL *)fileURL completion:(void (^)(BOOL success, unsigned long long fileSize, NSString *urlSuffix))completion;

@end

NS_ASSUME_NONNULL_END
