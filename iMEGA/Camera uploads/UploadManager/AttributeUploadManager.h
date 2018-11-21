
#import <Foundation/Foundation.h>
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AttributeUploadManager : NSObject

@property (strong, nonatomic) NSOperationQueue *operationQueue;

+ (instancetype)shared;

- (void)scanLocalAttributesAndRetryUploadIfNeeded;

- (void)uploadAttributeAtURL:(NSURL *)URL withAttributeType:(MEGAAttributeType)type forNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
