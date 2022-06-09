
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageExportManager : NSObject

+ (instancetype)shared;

- (void)exportImageAtURL:(NSURL *)imageURL dataTypeUTI:(NSString *)dataUTI toURL:(NSURL *)outputURL outputTypeUTI:(nullable NSString *)outputUTI shouldStripGPSInfo:(BOOL)shouldStripGPSInfo completion:(void (^)(BOOL))completion;

@end

NS_ASSUME_NONNULL_END
