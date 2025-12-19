#import "PhotosViewController.h"

#import "UIScrollView+EmptyDataSet.h"
#import "EmptyStateView.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UICollectionView+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "CameraUploadsTableViewController.h"
#import "CameraUploadManager.h"
#import "CameraUploadManager+Settings.h"
#import "UIViewController+MNZCategory.h"
#import "NSArray+MNZCategory.h"

#import "LocalizationHelper.h"
@import StoreKit;
@import Photos;
@import MEGAUIKit;

@interface PhotosViewController ()

@property (weak, nonatomic) IBOutlet UIView *photoContainerView;

@property (nonatomic) NSLayoutConstraint *stateViewHeightConstraint;
@end

@implementation PhotosViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupBindings];
    [self configureContextMenuManager];
    [self configPhotoContainerView];
    [self updateAppearance];
    [self setupBarButtons];
    [self configureImages];
}

- (void)setupBarButtons {
    self.editBarButtonItem = [self makeEditBarButton];
    self.cancelBarButtonItem = [self makeCancelBarButton];
    self.filterBarButtonItem = [self makeFilterActiveBarButton];
    self.cameraUploadStatusBarButtonItem = [self makeCameraUploadStatusBarButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.viewModel updateNavigationTitleViewToCheckForUploads];
    [self.viewModel startMonitoringUpdates];
    
    [self.photoUpdatePublisher setupSubscriptions];
    
    if (!MEGAReachabilityManager.isReachable) {
        self.editBarButtonItem.enabled = NO;
    }
    
    [self.viewModel loadAllPhotosWithSavedFilters];
    
    [self setupNavigationBarButtons];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.viewModel cancelLoading];
    
    [self.photoUpdatePublisher cancelSubscriptions];
}

#pragma mark - config views
- (void)configPhotoContainerView {
    [self objcWrapper_configPhotoLibraryViewIn:self.photoContainerView];
}

- (PhotoSelectionAdapter *)selection {
    if (_selection == nil) {
        _selection = [[PhotoSelectionAdapter alloc] initWithSdk:MEGASdk.shared];
    }
    
    return _selection;
}

- (DefaultNodeAccessoryActionDelegate *)defaultNodeAccessoryActionDelegate {
    if (_defaultNodeAccessoryActionDelegate == nil) {
        _defaultNodeAccessoryActionDelegate = [DefaultNodeAccessoryActionDelegate new];
    }
    return _defaultNodeAccessoryActionDelegate;
}

- (NSMutableSet *)subscriptions {
    if (_subscriptions == nil) {
        _subscriptions = [NSMutableSet set];
    }
    return _subscriptions;
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)reloadPhotos {
    [self.viewModel resetNavigationTitleView];
    [self setupNavigationBarButtons];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self objcWrapper_updatePhotoLibrary];
        [self setupNavigationBarButtons];
    });
}

#pragma mark - IBAction

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self objcWrapper_configPhotoLibrarySelectAll];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self objcWrapper_enablePhotoLibraryEditMode:editing];
    
    if (editing) {
        UITabBar *tabBar = self.tabBarController.tabBar;
        if (tabBar == nil) {
            return;
        }
        
        if (![self.tabBarController.view.subviews containsObject:self.toolbar]) {
            [self setUpToolbar];
            
            [UIView animateWithDuration:0.33f animations:^ {
                [self.toolbar setAlpha:1.0];
                
                if ([self isLiquidGlassEnabled]) {
                    self.tabBarController.tabBar.alpha = 0.0;
                }
            }];
        }
    } else {
        [self.viewModel resetNavigationTitleView];
        
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:0.0];
            
            if ([self isLiquidGlassEnabled]) {
                self.tabBarController.tabBar.alpha = 1.0;
            }
        } completion:^(BOOL finished) {
            if (finished) {
                [self.toolbar removeFromSuperview];
            }
        }];
    }
}

- (void)didSelectedPhotoCountChange:(NSInteger)count {
    [self objcWrapper_updateNavigationTitleWithSelectedPhotoCount:count];
    [self setToolbarActionsEnabledIn:self.toolbar isEnabled:count > 0];
}

@end
