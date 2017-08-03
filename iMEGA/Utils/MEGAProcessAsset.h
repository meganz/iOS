
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface MEGAProcessAsset : NSObject

- (instancetype)initWithAsset:(PHAsset *)asset filePath:(void (^)(NSString *filePath))filePath node:(void(^)(MEGANode *node))node error:(void (^)(NSError *error))error;
- (void)prepare;

@end
