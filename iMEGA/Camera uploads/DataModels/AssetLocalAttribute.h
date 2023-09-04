#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetLocalAttribute : NSObject

@property (strong, nonatomic) NSURL *attributeDirectoryURL;

@property (readonly) NSURL *fingerprintURL;
@property (readonly) NSString *savedFingerprint;

@property (readonly) NSURL *thumbnailURL;
@property (readonly) BOOL hasSavedThumbnail;

@property (readonly) NSURL *previewURL;
@property (readonly) BOOL hasSavedPreview;

@property (readonly) BOOL hasSavedAttributes;

- (instancetype)initWithAttributeDirectoryURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
