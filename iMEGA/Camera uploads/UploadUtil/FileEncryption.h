
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MEGABackgroundMediaUpload;

@interface FileEncryption : NSObject

- (instancetype)initWithMediaUpload:(MEGABackgroundMediaUpload *)mediaUpload outputFileURL:(NSURL *)outputFileURL;

- (void)encryptFileAtURL:(NSURL *)fileURL completion:(void (^)(BOOL success, unsigned long long fileSize, NSDictionary<NSString *, NSURL *> * _Nullable chunkURLsKeyedByUploadSuffix, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
