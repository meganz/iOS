#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MyAvatarManager, PhotoLibraryContentViewModel, PhotoUpdatePublisher, PhotoSelectionAdapter, PhotoAlbumContainerViewController, PhotosViewModel, ContextMenuManager, DefaultNodeAccessoryActionDelegate;

@interface PhotosViewController : UIViewController <MEGATransferDelegate, MEGAGlobalDelegate>

@property (nonatomic, strong) NSMutableArray *photosByMonthYearArray;

@property (nonatomic, nullable, strong) MyAvatarManager *myAvatarManager;
@property (strong, nonatomic) PhotoSelectionAdapter *selection;
@property (strong, nonatomic) PhotoLibraryContentViewModel *photoLibraryContentViewModel;

@property (weak,   nonatomic) PhotoAlbumContainerViewController *parentPhotoAlbumsController;
@property (assign, nonatomic) BOOL shouldShowRightBarButton;

@property (nonatomic) IBOutlet UIView *photosBannerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *cancelBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *filterBarButtonItem;
@property (nonatomic, strong, nullable) UIBarButtonItem *cameraUploadStatusBarButtonItem;
@property (nonatomic, strong) PhotosViewModel *viewModel;
@property (strong, nonatomic) PhotoUpdatePublisher *photoUpdatePublisher;
@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;
@property (nonatomic, strong, nullable) UIView *emptyStateView;
@property (strong, nonatomic) DefaultNodeAccessoryActionDelegate *defaultNodeAccessoryActionDelegate;

- (void)reloadPhotos;
- (void)setToolbarActionsEnabled:(BOOL)boolValue;
- (void)didSelectedPhotoCountChange:(NSInteger)count;
- (void)buttonTouchUpInsideEmptyState;

- (nullable NSString *)titleForEmptyState;
- (NSString *)descriptionForEmptyState;
- (nullable UIImage *)imageForEmptyState;
- (NSString *)buttonTitleForEmptyState;

@end

NS_ASSUME_NONNULL_END
