
#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@class MyAvatarManager, PhotoLibraryContentViewModel, PhotoUpdatePublisher, PhotoSelectionAdapter, WarningViewModel, PhotoAlbumContainerViewController, PhotoViewModel, ContextMenuManager;

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

@property (weak,   nonatomic) PhotoAlbumContainerViewController *parentPhotoAlbumsController;
@property (assign, nonatomic) BOOL shouldShowRightBarButton;

@property (nonatomic) IBOutlet UIView *photosBannerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (nonatomic, strong) PhotoViewModel *viewModel;
@property (strong, nonatomic) PhotoUpdatePublisher *photoUpdatePublisher;

@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;

- (void)reloadHeader;
- (void)reloadPhotos;
- (void)showToolbar:(BOOL)showToolbar;
- (void)setToolbarActionsEnabled:(BOOL)boolValue;
- (void)didSelectedPhotoCountChange:(NSInteger)count;
- (void)hideRightBarButtonItem:(BOOL)shouldHide;
- (void)buttonTouchUpInsideEmptyState;

@end

NS_ASSUME_NONNULL_END
