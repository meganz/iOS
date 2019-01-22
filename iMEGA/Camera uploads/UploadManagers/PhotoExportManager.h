
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoExportManager : NSObject

+ (instancetype)shared;

- (void)exportPhotoData:(NSData *)data dataTypeUTI:(NSString *)dataUTI outputURL:(NSURL *)outputURL outputTypeUTI:(NSString *)outputUTI shouldStripGPSInfo:(BOOL)shouldStripGPSInfo completion:(void (^)(BOOL))completion;

@end

NS_ASSUME_NONNULL_END
