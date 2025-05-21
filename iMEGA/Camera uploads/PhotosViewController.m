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

@import MEGAL10nObjc;
@import StoreKit;
@import Photos;
@import MEGAUIKit;

@interface PhotosViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (weak, nonatomic) IBOutlet UIView *photoContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *photosCollectionView;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic) NSLayoutConstraint *stateViewHeightConstraint;
@end

@implementation PhotosViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureContextMenuManager];
    [self configPhotoContainerView];
    [self updateAppearance];
    [self setupBarButtons];
    [self updateNavigationTitleBar];
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
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveInternetConnectionChangedNotification) name:kReachabilityChangedNotification object:nil];
    
    [MEGASdk.shared addMEGAGlobalDelegateAsync:self queueType:ListenerQueueTypeGlobalBackground];
    
    [self.photoUpdatePublisher setupSubscriptions];
    
    if (!MEGAReachabilityManager.isReachable) {
        self.editBarButtonItem.enabled = NO;
    }
    
    [self.viewModel loadAllPhotosWithSavedFilters];
    [self refreshMyAvatar];
    
    [self setupNavigationBarButtons];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [MEGASdk.shared removeMEGAGlobalDelegateAsync:self];
    
    [self.photoUpdatePublisher cancelSubscriptions];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self handleEmptyStateReload];
    } completion:nil];
}

#pragma mark - config views
- (void)configPhotoContainerView {
    self.photosCollectionView.emptyDataSetSource = self;
    self.photosCollectionView.emptyDataSetDelegate = self;
    
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

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)reloadPhotos {
    [self updateNavigationTitleBar];
    [self setupNavigationBarButtons];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self objcWrapper_updatePhotoLibrary];
        [self handleEmptyStateReload];
        [self setupNavigationBarButtons];
    });
}

- (void)handleEmptyStateReload {
    if (MEGAReachabilityManager.isReachable && self.viewModel.hasNoPhotos) {
        [self showEmptyViewForAppliedFilters];
    } else {
        [self removeEmptyView];
        [self.photosCollectionView reloadEmptyDataSet];
    }
}

- (void)updateNavigationTitleBar {
    self.objcWrapper_parent.navigationItem.title = LocalizedString(@"photo.navigation.title", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
}

#pragma mark - notifications

- (void)didReceiveInternetConnectionChangedNotification {
    if (!MEGAReachabilityManager.isReachable) {
        self.editBarButtonItem.enabled = NO;
    }
    
    [self handleEmptyStateReload];
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
            [self objcWrapper_updateNavigationTitleWithSelectedPhotoCount:0];
            [self.toolbar setAlpha:0.0];
            
            [self updateBarButtonItemsIn:self.toolbar];
            [self.tabBarController.view addSubview:self.toolbar];
            self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [self.toolbar setBackgroundColor:[UIColor surface1Background]];
            
            NSLayoutAnchor *bottomAnchor = self.tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor;
            
            [NSLayoutConstraint activateConstraints:@[[self.toolbar.topAnchor constraintEqualToAnchor:self.tabBarController.tabBar.topAnchor constant:0],
                                                      [self.toolbar.leadingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.leadingAnchor constant:0],
                                                      [self.toolbar.trailingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.trailingAnchor constant:0],
                                                      [self.toolbar.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:0]]];
            
            [UIView animateWithDuration:0.33f animations:^ {
                [self.toolbar setAlpha:1.0];
            }];
        }
    } else {
        [self updateNavigationTitleBar];
        [self.photosCollectionView reloadEmptyDataSet];
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:0.0];
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

#pragma mark - View transitions

- (void)pushCameraUploadSettings {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CameraUploadSettings" bundle:nil];
    CameraUploadsTableViewController *cameraUploadsTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"CameraUploadsSettingsID"];
    [self.navigationController pushViewController:cameraUploadsTableViewController animated:YES];
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [self emptyStateViewWithImage:[self imageForEmptyState]
                                                             title:[self titleForEmptyState]
                                                       description:[self descriptionForEmptyState]
                                                       buttonTitle:[self buttonTitleForEmptyState]];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (CameraUploadManager.isCameraUploadEnabled) {
            text = LocalizedString(@"cameraUploadsEnabled", @"");
        } else {
            text = LocalizedString(@"enableCameraUploadsButton", @"Enable Camera Uploads");
        }
    } else {
        text = LocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (MEGAReachabilityManager.isReachable && !CameraUploadManager.isCameraUploadEnabled) {
        text = LocalizedString(@"Automatically backup your photos and videos to the Cloud Drive.", @"");
    } else if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    UIImage *image = nil;
    if ([MEGAReachabilityManager isReachable]) {
        if (CameraUploadManager.isCameraUploadEnabled) {
            image = [UIImage megaImageWithNamed:@"cameraEmptyState"];
        } else {
            image = [UIImage megaImageWithNamed:@"cameraUploadsBoarding"];
        }
    } else {
        image = [UIImage megaImageWithNamed:@"noInternetEmptyState"];
    }
    
    return image;
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (!CameraUploadManager.isCameraUploadEnabled) {
            text = LocalizedString(@"enable", @"Text button shown when the chat is disabled and if tapped the chat will be enabled");
        }
    } else {
        if (!MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            text = LocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
        }
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    if (MEGAReachabilityManager.isReachable) {
        [self pushCameraUploadSettings];
    } else {
        if (!MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self.viewModel onCameraAndMediaNodesUpdateWithNodeList:nodeList];
}

@end
