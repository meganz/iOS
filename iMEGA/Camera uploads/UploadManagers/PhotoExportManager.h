
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoExportManager : NSObject

+ (instancetype)shared;

@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

NS_ASSUME_NONNULL_END
