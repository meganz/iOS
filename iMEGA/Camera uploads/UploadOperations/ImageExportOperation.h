#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImageExportOperation : MEGAOperation

- (instancetype)initWithImageURL:(NSURL *)imageURL outputURL:(NSURL *)outputURL outputImageTypeUTI:(nullable NSString *)UTI shouldStripGPSInfo:(BOOL)shouldStripGPSInfo completion:(void (^)(BOOL succeeded))completion;

@end

NS_ASSUME_NONNULL_END
