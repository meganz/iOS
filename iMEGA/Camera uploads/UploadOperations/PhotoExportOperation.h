
#import "MEGABackgroundTaskOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface PhotoExportOperation : MEGABackgroundTaskOperation

- (instancetype)initWithPhotoData:(NSData *)data outputURL:(NSURL *)URL outputImageTypeUTI:(nullable NSString *)UTI shouldStripGPSInfo:(BOOL)shouldStripGPSInfo completionHandler:(void (^)(BOOL succeeded))handler;

@end

NS_ASSUME_NONNULL_END
