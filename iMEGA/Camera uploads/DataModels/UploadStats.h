
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UploadStats : NSObject

@property (nonatomic) NSUInteger pendingFilesCount;
@property (nonatomic) NSUInteger totalFilesCount;
@property (nonatomic) NSUInteger uploadDoneFilesCount;

@end

NS_ASSUME_NONNULL_END
