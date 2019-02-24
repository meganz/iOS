
#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface PhotoExportOperation : MEGAOperation

- (instancetype)initWithPhotoData:(NSData *)data outputURL:(NSURL *)URL outputImageTypeUTI:(nullable NSString *)UTI shouldStripGPSInfo:(BOOL)shouldStripGPSInfo completion:(void (^)(BOOL succeeded))completion;

@end

NS_ASSUME_NONNULL_END
