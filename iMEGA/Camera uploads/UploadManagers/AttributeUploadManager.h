
#import <Foundation/Foundation.h>
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CLLocation;

@interface AttributeUploadManager : NSObject

+ (instancetype)shared;

- (void)waitUnitlAllAttributeUploadsAreFinished;

- (void)scanLocalAttributeFilesAndRetryUploadIfNeeded;

- (void)uploadFile:(NSURL *)URL withAttributeType:(MEGAAttributeType)type forNode:(MEGANode *)node;

- (void)uploadCoordinateLocation:(CLLocation *)location forNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
