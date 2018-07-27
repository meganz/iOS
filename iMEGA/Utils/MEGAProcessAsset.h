
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

static NSString *MEGAProcessAssetErrorDomain = @"MEGAProcessAssetErrorDomain";

@interface MEGAProcessAsset : NSObject

/* if YES keep asset original name, for example: IMG_XXXX.JPG */
@property (nonatomic, getter=isOriginalName) BOOL originalName;

- (instancetype)initWithAsset:(PHAsset *)asset parentNode:(MEGANode *)parentNode cameraUploads:(BOOL)cameraUploads filePath:(void (^)(NSString *filePath))filePath node:(void(^)(MEGANode *node))node error:(void (^)(NSError *error))error;
- (instancetype)initToShareThroughChatWithAsset:(PHAsset *)asset filePath:(void (^)(NSString *filePath))filePath node:(void(^)(MEGANode *node))node error:(void (^)(NSError *error))error;
- (instancetype)initToShareThroughChatWithAssets:(NSArray <PHAsset *> *)assets filePaths:(void (^)(NSArray <NSString *> *filePaths))filePaths nodes:(void(^)(NSArray <MEGANode *> *nodes))nodes errors:(void (^)(NSArray <NSError *> *errors))errors;
- (void)prepare;

@end
