
#import <Foundation/Foundation.h>
#import "MEGASdkManager.h"
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface AssetUploadInfo : NSObject <NSCoding>

@property (strong, nonatomic) PHAsset *asset;
@property (strong, nonatomic) NSString *savedLocalIdentifier;
@property (strong, nonatomic) NSString *fileName;
@property (nonatomic) unsigned long long fileSize;
@property (strong, nonatomic, nullable) CLLocation *location;

@property (strong, nonatomic) NSString *fingerprint;
@property (strong, nonatomic) NSString *originalFingerprint;

@property (strong, nonatomic) NSURL *directoryURL;
@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSURL *previewURL;
@property (nonatomic, readonly) NSURL *thumbnailURL;

@property (nonatomic, readonly) NSURL *encryptionDirectoryURL;
@property (strong, nonatomic) NSDictionary<NSString *, NSURL *> *encryptedChunkURLsKeyedByUploadSuffix;
@property (nonatomic) NSUInteger encryptedChunksCount;

@property (strong, nonatomic) NSString *uploadURLString;

@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUpload;
@property (strong, nonatomic) MEGANode *parentNode;

- (instancetype)initWithAsset:(PHAsset *)asset savedIdentifier:(NSString *)savedIdentifier parentNode:(MEGANode *)parentNode;

@end

NS_ASSUME_NONNULL_END
