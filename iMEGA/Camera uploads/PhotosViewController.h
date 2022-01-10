
#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@class MyAvatarManager, PhotoLibraryContentViewModel, PhotoLibraryPublisher, PhotoUpdatePublisher;

typedef NS_ENUM(NSUInteger, MEGACameraUploadsState) {
    MEGACameraUploadsStateDisabled,
    MEGACameraUploadsStateUploading,
    MEGACameraUploadsStateCompleted,
    MEGACameraUploadsStateNoInternetConnection,
    MEGACameraUploadsStateEmpty,
    MEGACameraUploadsStateLoading,
    MEGACameraUploadsStateEnableVideo
};

@interface PhotosViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, MEGARequestDelegate, MEGATransferDelegate, MEGAGlobalDelegate>

@property (nonatomic, nullable, strong) MyAvatarManager *myAvatarManager;
@property (strong, nonatomic) PhotoLibraryContentViewModel *photoLibraryContentViewModel;
@property (strong, nonatomic) PhotoUpdatePublisher *photoUpdatePublisher;

- (void)reloadHeader;
- (void)reloadPhotos;

@end

NS_ASSUME_NONNULL_END
