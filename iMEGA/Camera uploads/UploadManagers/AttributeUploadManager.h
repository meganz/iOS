
#import <Foundation/Foundation.h>
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CLLocation;

@interface AttributeUploadManager : NSObject

+ (instancetype)shared;

- (void)waitUnitlAllAttributeUploadsAreFinished;

- (void)scanLocalAttributeFilesAndRetryUploadIfNeeded;

- (void)uploadFileAtURL:(NSURL *)URL withAttributeType:(MEGAAttributeType)type forNode:(MEGANode *)node;

- (void)uploadCoordinateAtLocation:(CLLocation *)location forNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
