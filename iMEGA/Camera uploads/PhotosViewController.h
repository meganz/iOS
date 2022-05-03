
#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@class MyAvatarManager, PhotoLibraryContentViewModel, PhotoUpdatePublisher, PhotoSelectionAdapter, WarningViewModel;

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
@property (strong, nonatomic) PhotoSelectionAdapter *selection;
@property (strong, nonatomic) PhotoLibraryContentViewModel *photoLibraryContentViewModel;
@property (strong, nonatomic) WarningViewModel *warningViewModel;
@property (strong, nonatomic) PhotoUpdatePublisher *photoUpdatePublisher;

@property (nonatomic) IBOutlet UIView *photosBannerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

- (void)reloadHeader;
- (void)reloadPhotos;
- (void)showToolbar:(BOOL)showToolbar;
- (void)setToolbarActionsEnabled:(BOOL)boolValue;
- (void)didSelectedPhotoCountChange:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
