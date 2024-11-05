#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

static NSString *MEGAProcessAssetErrorDomain = @"MEGAProcessAssetErrorDomain";

NS_SWIFT_SENDABLE
@interface MEGAProcessAsset : NSObject

/* if YES keep asset original name, for example: IMG_XXXX.JPG */
@property (nonatomic, getter=isOriginalName) BOOL originalName;

- (instancetype)initWithAsset:(PHAsset *)asset filePath:(void (^)(NSString *filePath))filePath error:(void (^)(NSError *error))error;
- (instancetype)initToShareThroughChatWithAssets:(NSArray <PHAsset *> *)assets filePaths:(void (^)(NSArray <NSString *> *filePaths))filePaths errors:(void (^)(NSArray <NSError *> *errors))errors;
- (instancetype)initToShareThroughChatWithVideoURL:(NSURL *)videoURL filePath:(void (^)(NSString *filePath))filePath error:(void (^)(NSError *error))error;
- (instancetype)initToShareThroughChatWithVideoURL:(NSURL *)videoURL filePath:(void (^)(NSString *filePath))filePath error:(void (^)(NSError *error))error presenter:(UIViewController *)presenter;
- (void)prepare;

@end
