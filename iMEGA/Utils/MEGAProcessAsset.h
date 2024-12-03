#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN
static NSString *MEGAProcessAssetErrorDomain = @"MEGAProcessAssetErrorDomain";

NS_SWIFT_SENDABLE
@interface MEGAProcessAsset : NSObject

/* if YES keep asset original name, for example: IMG_XXXX.JPG */
@property (nonatomic, getter=isOriginalName) BOOL originalName;

- (instancetype)initWithAsset:(PHAsset *)asset
                    presenter:(nullable UIViewController *)presenter
                     filePath:(void (^)(NSString *filePath))filePath
                        error:(void (^)(NSError *error))error;

- (instancetype)initToShareThroughChatWithAssets:(NSArray <PHAsset *> *)assets
                                       presenter:(UIViewController *)presenter
                                       filePaths:(void (^)(NSArray <NSString *> * _Nullable filePaths))filePaths
                                          errors:(void (^)(NSArray <NSError *> * _Nullable errors))errors;

- (instancetype)initToShareThroughChatWithVideoURL:(NSURL *)videoURL
                                         presenter:(UIViewController *)presenter
                                          filePath:(void (^)(NSString * _Nullable filePath))filePath
                                             error:(void (^)(NSError * _Nullable error))error;

- (instancetype)initToShareThroughChatWithVideoURL:(NSURL *)videoURL
                                          filePath:(void (^)(NSString * _Nullable filePath))filePath
                                             error:(void (^)(NSError * _Nullable error))error
                                         presenter:(UIViewController *)presenter;
- (void)prepare;

@end
NS_ASSUME_NONNULL_END
