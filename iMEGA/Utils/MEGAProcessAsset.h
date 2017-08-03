
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

static NSString *MEGAProcessAssetErrorDomain = @"MEGAProcessAssetErrorDomain";

@interface MEGAProcessAsset : NSObject

- (instancetype)initWithAsset:(PHAsset *)asset parentNode:(MEGANode *)parentNode filePath:(void (^)(NSString *filePath))filePath node:(void(^)(MEGANode *node))node error:(void (^)(NSError *error))error;
- (void)prepare;

@end
