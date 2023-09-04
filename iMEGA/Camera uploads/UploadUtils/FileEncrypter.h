#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MEGABackgroundMediaUpload;

@interface FileEncrypter : NSObject

- (instancetype)initWithMediaUpload:(MEGABackgroundMediaUpload *)mediaUpload outputDirectoryURL:(NSURL *)outputDirectoryURL shouldTruncateInputFile:(BOOL)shouldTruncateInputFile;

- (void)encryptFileAtURL:(NSURL *)fileURL completion:(void (^)(unsigned long long fileSize, NSDictionary<NSString *, NSURL *> * _Nullable chunkURLsKeyedByUploadSuffix, NSError * _Nullable error))completion;

- (void)cancelEncryption;

@end

NS_ASSUME_NONNULL_END
