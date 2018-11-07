
#import <Foundation/Foundation.h>
#import "MEGASdkManager.h"
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface AssetUploadInfo : NSObject <NSCoding>

@property (strong, nonatomic) PHAsset *asset;
@property (strong, nonatomic) NSString *fileName;
@property (nonatomic) NSUInteger fileSize;

@property (strong, nonatomic) NSString *fingerprint;
@property (strong, nonatomic) NSString *originalFingerprint;

@property (strong, nonatomic) NSURL *directoryURL;
@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSURL *previewURL;
@property (nonatomic, readonly) NSURL *thumbnailURL;
@property (nonatomic, readonly) NSURL *encryptedURL;
@property (nonatomic, readonly) NSURL *originalURL;

@property (strong, nonatomic) NSString *uploadURLStringSuffix;
@property (strong, nonatomic) NSString *uploadURLString;
@property (nonatomic, readonly) NSURL *uploadURL;

@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUpload;
@property (strong, nonatomic) MEGANode *parentNode;

- (instancetype)initWithAsset:(PHAsset *)asset parentNode:(MEGANode *)parentNode;

@end

NS_ASSUME_NONNULL_END
