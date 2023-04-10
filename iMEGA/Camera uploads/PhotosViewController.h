
#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@class MyAvatarManager, PhotoLibraryContentViewModel, PhotoUpdatePublisher, PhotoSelectionAdapter, WarningViewModel, PhotoAlbumContainerViewController, PhotosViewModel, ContextMenuManager;

typedef NS_ENUM(NSUInteger, MEGACameraUploadsState) {
    MEGACameraUploadsStateDisabled,
    MEGACameraUploadsStateUploading,
    MEGACameraUploadsStateCompleted,
    MEGACameraUploadsStateNoInternetConnection,
    MEGACameraUploadsStateEmpty,
    MEGACameraUploadsStateLoading,
    MEGACameraUploadsStateEnableVideo
};

@interface PhotosViewController : UIViewController <MEGATransferDelegate, MEGAGlobalDelegate>

@property (nonatomic, strong) NSMutableArray *photosByMonthYearArray;

@property (nonatomic, nullable, strong) MyAvatarManager *myAvatarManager;
@property (strong, nonatomic) PhotoSelectionAdapter *selection;
@property (strong, nonatomic) PhotoLibraryContentViewModel *photoLibraryContentViewModel;
@property (strong, nonatomic) WarningViewModel *warningViewModel;

@property (weak,   nonatomic) PhotoAlbumContainerViewController *parentPhotoAlbumsController;
@property (assign, nonatomic) BOOL shouldShowRightBarButton;

@property (nonatomic) IBOutlet UIView *photosBannerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *cancelBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *filterBarButtonItem;
@property (nonatomic, strong) PhotosViewModel *viewModel;
@property (strong, nonatomic) PhotoUpdatePublisher *photoUpdatePublisher;
@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;

- (void)reloadHeader;
- (void)reloadPhotos;
- (void)setToolbarActionsEnabled:(BOOL)boolValue;
- (void)didSelectedPhotoCountChange:(NSInteger)count;
- (void)buttonTouchUpInsideEmptyState;

- (NSString *)titleForEmptyState;
- (NSString *)descriptionForEmptyState;
- (UIImage *)imageForEmptyState;
- (NSString *)buttonTitleForEmptyState;

@end

NS_ASSUME_NONNULL_END
