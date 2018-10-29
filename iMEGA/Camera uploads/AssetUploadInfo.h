
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MEGABackgroundMediaUpload;

@interface AssetUploadInfo : NSObject <NSCoding>

@property (strong, nonatomic) NSString *localIdentifier;
@property (strong, nonatomic) NSString *fileName;
@property (nonatomic) NSUInteger fileSize;

@property (strong, nonatomic) NSString *fingerprint;
@property (strong, nonatomic) NSString *originalFingerprint;

@property (strong, nonatomic) NSURL *directoryURL;
@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSURL *previewURL;
@property (nonatomic, readonly) NSURL *thumbnailURL;
@property (nonatomic, readonly) NSURL *encryptedURL;

@property (strong, nonatomic) NSString *uploadURLStringSuffix;
@property (strong, nonatomic) NSString *uploadURLString;
@property (nonatomic, readonly) NSURL *uploadURL;

@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUpload;
@property (nonatomic) uint64_t parentHandle;

@end

NS_ASSUME_NONNULL_END
