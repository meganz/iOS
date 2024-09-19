#import "MEGAPhotoBrowserViewController.h"

#import "PieChartView.h"
#import "SVProgressHUD.h"

#import "BrowserViewController.h"
#import "CloudDriveViewController.h"
#import "Helper.h"
#import "MainTabBarController.h"
#import "MEGAGetPreviewRequestDelegate.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGAPhotoBrowserAnimator.h"
#import "MEGAPhotoBrowserPickerViewController.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStartDownloadTransferDelegate.h"
#import "SendToViewController.h"

#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIDevice+MNZCategory.h"
#import "MEGA-Swift.h"
#import "NSArray+MNZCategory.h"

@import MEGAL10nObjc;
@import MEGAUIKit;
@import MEGASDKRepo;

static const CGFloat GapBetweenPages = 10.0;
static const long long MaxSizeToDownloadOriginal = 50 * 1024 * 1024; // 50 MB. Download original as long it's smaller than 50MB
static const long long MinSizeToRequestThePreview = 1 * 1024 * 1024; // 1 MB. Don't request the preview and download the original if the photo is smaller than 1 MB

@interface MEGAPhotoBrowserViewController () <UIScrollViewDelegate, UIViewControllerTransitioningDelegate, PieChartViewDelegate, PieChartViewDataSource, NodeActionViewControllerDelegate, NodeInfoViewControllerDelegate, MEGADelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (weak, nonatomic) IBOutlet UIView *statusBarBackground;
@property (weak, nonatomic) IBOutlet PieChartView *pieChartView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *customActionsButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftToolbarItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightToolbarItem;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewTrailingConstraint;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveToolbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *importToolbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *exportFileToolbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *forwardToolbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *allMediaToolBarItem;

@property (nonatomic) NSCache<NSNumber *, UIScrollView *> *imageViewsCache;
@property (nonatomic) NSCache<NSNumber *, NSNumber *> *imageViewsZoomCache;
@property (nonatomic) UIImageView *targetImageView;

@property (nonatomic) CGPoint panGestureInitialPoint;
@property (nonatomic) CGRect panGestureInitialFrame;
@property (nonatomic, getter=isInterfaceHidden) BOOL interfaceHidden;
@property (nonatomic) CGFloat playButtonSize;
@property (nonatomic) double transferProgress;

@property (nonatomic) SendLinkToChatsDelegate *sendLinkDelegate;

@end

@implementation MEGAPhotoBrowserViewController

+ (MEGAPhotoBrowserViewController *)photoBrowserWithMediaNodes:(NSMutableArray<MEGANode *> *)mediaNodesArray api:(MEGASdk *)api displayMode:(DisplayMode)displayMode isFromSharedItem:(BOOL)isFromSharedItem presentingNode:(MEGANode *)node {
    PhotoBrowserDataProvider *provider = [[PhotoBrowserDataProvider alloc] initWithCurrentPhoto:node allPhotos:mediaNodesArray sdk:api];
    
    MEGAPhotoBrowserViewController *photoBrowser = [self photoBrowserWithProvider:provider api:api displayMode:displayMode isFromSharedItem:isFromSharedItem];
    [photoBrowser updateProviderNodeEntitiesWithNodes: mediaNodesArray];
    return photoBrowser;
}

+ (MEGAPhotoBrowserViewController *)photoBrowserWithMediaNodes:(NSMutableArray<MEGANode *> *)mediaNodesArray api:(MEGASdk *)api displayMode:(DisplayMode)displayMode isFromSharedItem:(BOOL)isFromSharedItem preferredIndex:(NSUInteger)preferredIndex {
    PhotoBrowserDataProvider *provider  = [[PhotoBrowserDataProvider alloc] initWithCurrentIndex:preferredIndex allPhotos:mediaNodesArray sdk:api];
    return [self photoBrowserWithProvider:provider api:api displayMode:displayMode isFromSharedItem:isFromSharedItem];
}

+ (MEGAPhotoBrowserViewController *)photoBrowserWithProvider:(PhotoBrowserDataProvider *)provider api:(MEGASdk *)api displayMode:(DisplayMode)displayMode isFromSharedItem:(BOOL)isFromSharedItem {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PhotoBrowser" bundle:[NSBundle bundleForClass:[self class]]];
    MEGAPhotoBrowserViewController *photoBrowserVC = [storyboard instantiateViewControllerWithIdentifier:@"MEGAPhotoBrowserViewControllerID"];
    photoBrowserVC.dataProvider = provider;
    photoBrowserVC.api = api;
    photoBrowserVC.displayMode = displayMode;
    photoBrowserVC.isFromSharedItem = isFromSharedItem;
    
    return photoBrowserVC;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel onViewDidLoad];
    
    self.imageViewsZoomCache = [[NSCache<NSNumber *, NSNumber *> alloc] init];

    self.modalPresentationCapturesStatusBarAppearance = YES;
    self.panGestureInitialPoint = CGPointZero;
    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)]];
            
    self.scrollView.delegate = self;
    self.scrollView.tag = 1;
    self.transitioningDelegate = self;
    self.playButtonSize = 100.0f;
    self.scrollViewTrailingConstraint.constant = GapBetweenPages;
    
    self.pieChartView.delegate = self;
    self.pieChartView.datasource = self;
    self.pieChartView.layer.cornerRadius = self.pieChartView.frame.size.width/2;
    self.pieChartView.layer.masksToBounds = YES;
    
    self.leftToolbarItem.accessibilityIdentifier = @"leftToolbarItem";
    self.rightToolbarItem.accessibilityIdentifier = @"rightToolbarItem";

    switch (self.displayMode) {
        case DisplayModeFileLink:
            self.leftToolbarItem.image = [UIImage imageNamed:@"import"];
            self.rightToolbarItem.image = [UIImage imageNamed:@"share"];
            self.centerToolbarItem.image = [UIImage imageNamed:@"saveToPhotos"];
            break;
            
        case DisplayModeCloudDrive:
        case DisplayModeSharedItem:
            [self activateSlideShowButtonWithBarButtonItem:[self slideshowButton]];
            break;
        case DisplayModeRubbishBin:
            [self.toolbar setItems:@[self.leftToolbarItem]];
            break;
        case DisplayModeNodeInsideFolderLink:
            {
                UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
                [self.toolbar setItems:@[self.leftToolbarItem, flexibleItem, [self slideshowButton], flexibleItem]];
                [self activateSlideShowButtonWithBarButtonItem: [self slideshowButton]];
            }
            break;
        case DisplayModeChatAttachment:
            {
                UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
                [self.toolbar setItems:@[self.exportFileToolbarItem, flexibleItem, self.importToolbarItem, flexibleItem,  self.forwardToolbarItem, flexibleItem, self.customActionsButton]];
                self.allMediaToolBarItem.title = LocalizedString(@"All Media", @"");
                self.navigationItem.rightBarButtonItem = self.allMediaToolBarItem;
            }
            break;
        case DisplayModeAlbumLink:
            [self.leftToolbarItem setImage:NULL];
            self.leftToolbarItem.enabled = NO;
            [self activateSlideShowButtonWithBarButtonItem:[self slideshowButton]];
        default:
            break;
    }
    
    [self.toolbar setBackgroundColor:[UIColor surface1Background]];
    
    self.closeBarButtonItem.title = LocalizedString(@"close", @"A button label.");
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [MEGASdk.shared addMEGADelegate:self];
    [TransfersWidgetViewController.sharedTransferViewController setProgressViewInKeyWindow];
    [TransfersWidgetViewController.sharedTransferViewController bringProgressToFrontKeyWindowIfNeeded];
    [TransfersWidgetViewController.sharedTransferViewController updateProgressViewWithBottomConstant:-120];
    [TransfersWidgetViewController.sharedTransferViewController showWidgetIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.view layoutIfNeeded];
    if (self.isBeingPresented || self.needsReload) {
        [self reloadUI];
        self.needsReload = NO;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Main image
    UIImageView *placeholderCurrentImageView = self.placeholderCurrentImageView;
    [self.view addSubview:placeholderCurrentImageView];
    placeholderCurrentImageView.frame = self.view.bounds;
    
    // Activity indicator if main image is not yet loaded.
    UIActivityIndicatorView *activityIndicatorView = nil;
    if (placeholderCurrentImageView.image == nil) {
        activityIndicatorView = [self addActivityIndicatorToView:self.view];
    }
    
    // If it is video play icon.
    UIImageView *placeholderPlayImageView = self.placeholderPlayImageView;
    if (placeholderPlayImageView != nil) {
        [self.view addSubview:placeholderPlayImageView];
        placeholderPlayImageView.center = CGPointMake(self.view.bounds.size.width/2,
                                                      self.view.bounds.size.height/2.0);
        // Top and bottom bar needs to be visible.
        [self.view sendSubviewToBack:placeholderPlayImageView];
    }
    
    // Top and bottom bar needs to be visible.
    [self.view sendSubviewToBack:placeholderCurrentImageView];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.view layoutIfNeeded];
        [self reloadUI];
        // The scrollview animation is not aligning with placeholderImageView animation.
        // So hiding the scroll when the animation is in progress.
        self.scrollView.hidden = YES;
        CGPoint center = CGPointMake(size.width/2, size.height/2.0);
        
        [UIView animateWithDuration:context.transitionDuration
                         animations:^{
            placeholderCurrentImageView.frame = CGRectMake(0, 0, size.width, size.height);
            placeholderPlayImageView.center = center;
            activityIndicatorView.center = center;
        }];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.scrollView.hidden = NO;
        [activityIndicatorView removeFromSuperview];
        [placeholderPlayImageView removeFromSuperview];
        [placeholderCurrentImageView removeFromSuperview];
        
        if (self.presentedViewController) {
            self.needsReload = YES;
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MEGASdk.shared removeMEGADelegateAsync:self];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceNavigationBarUpdate:self.navigationBar traitCollection:self.traitCollection];
        [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
        
        [self updateAppearance];
    }
    
    if (self.traitCollection.preferredContentSizeCategory != previousTraitCollection.preferredContentSizeCategory) {
        [self reloadTitleWithCompletionHandler:^{}];
    }
}

- (void)didReceiveMemoryWarning {
    [CrashlyticsLogger log:@"[Photo Browser] Did receive memory warning"];
    [self freeUpSpaceOnImageViewCache:self.imageViewsCache imageViewsZoomCache: self.imageViewsZoomCache scrollView:self.scrollView];
    [self reloadUI];
    [super didReceiveMemoryWarning];
}

- (PhotoBrowserViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [self makeViewModel];
    }
    return _viewModel;
}

- (DefaultNodeAccessoryActionDelegate *)defaultNodeAccessoryActionDelegate {
    if (_defaultNodeAccessoryActionDelegate == nil) {
        _defaultNodeAccessoryActionDelegate = [DefaultNodeAccessoryActionDelegate new];
    }
    return _defaultNodeAccessoryActionDelegate;
}

#pragma mark - Status bar

- (BOOL)prefersStatusBarHidden {
    return self.isInterfaceHidden;
}

#pragma mark - UI

- (void)reloadUI {
    if (!CGPointEqualToPoint(self.panGestureInitialPoint, CGPointZero)) {
        return;
    }
    for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }
    self.imageViewsCache = [[NSCache<NSNumber *, UIScrollView *> alloc] init];
    self.imageViewsCache.countLimit = 1000;
    
    if (self.dataProvider.count == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.dataProvider.count, self.scrollView.frame.size.height);
    
    [self loadNearbyImagesFromIndex:self.dataProvider.currentIndex];
    self.scrollView.contentOffset = CGPointMake(self.dataProvider.currentIndex * CGRectGetWidth(self.scrollView.frame), 0);
    [self reloadTitleWithCompletionHandler:^{}];
}

- (void)resetZooms {
    for (NSUInteger i = 0; i < self.dataProvider.count; i++) {
        UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(i)];
        if (zoomableView && zoomableView.zoomScale != 1.0f) {
            zoomableView.zoomScale = 1.0f;
            [self resizeImageView:(UIImageView *)zoomableView.subviews.firstObject];
        }
    }
}

- (void)toggleTransparentInterfaceForDismissal:(BOOL)transparent {
    self.view.backgroundColor = transparent ? UIColor.clearColor : [self backgroundColor];
    self.view.superview.superview.backgroundColor = transparent ? UIColor.clearColor : UIColor.systemBackgroundColor;
    self.statusBarBackground.layer.opacity = self.navigationBar.layer.opacity = self.toolbar.layer.opacity = transparent ? 0.0f : 1.0f;
    
    MEGANode *node = self.dataProvider.currentPhoto;
    if ([FileExtensionGroupOCWrapper verifyIsVideo:node.name]) {
        UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.dataProvider.currentIndex)];
        if (zoomableView) {
            zoomableView.subviews.lastObject.hidden = transparent;
        }
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    
    [super dismissViewControllerAnimated:flag completion:^{
        if (self.displayMode == DisplayModeFileLink) {
            MEGALinkManager.secondaryLinkURL = nil;
        }
        
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Private

- (void)shareFileLink {
    NSString *link = self.encryptedLink ? self.encryptedLink : self.publicLink;
    NSArray *excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
    
    [self presentActivityVC:@[link] excludedActivityTypes:excludedActivityTypes sender:self.rightToolbarItem];
}

- (void)sendLinkToChat {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"SendToNavigationControllerID"];
    SendToViewController *sendToViewController = navigationController.viewControllers.firstObject;
    sendToViewController.sendMode = SendModeFileAndFolderLink;
    self.sendLinkDelegate = [SendLinkToChatsDelegate.alloc initWithLink:self.encryptedLink ? self.encryptedLink : self.publicLink navigationController:self.navigationController];
    sendToViewController.sendToViewControllerDelegate = self.sendLinkDelegate;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)updateAppearance {
    self.statusBarBackground.backgroundColor = self.navigationBar.backgroundColor = [UIColor surface1Background];
    
    [self reloadTitleWithCompletionHandler:^{}];
    
    self.view.backgroundColor = [self backgroundColor];
}

- (CGFloat)maximumZoomScaleWith:(MEGANode *)node zoomableView:(UIScrollView *)zoomableView imageView:(UIView *)imageView {
    return ([FileExtensionGroupOCWrapper verifyIsImage:node.name]) ? FLT_MAX : 1.0f;
}

- (NSArray *)keyCommands {
    UIKeyCommand *leftArrow = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(didInvokeLeftArrowCommand:)];
    UIKeyCommand *rightArrow = [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(didInvokeRightArrowCommand:)];
    return @[leftArrow, rightArrow];
}

- (void)didInvokeLeftArrowCommand:(UIKeyCommand *)keyCommand {
    NSInteger newIndex = self.dataProvider.currentIndex - 1;
    [self showPhotoAtIndex:newIndex];
}

- (void)didInvokeRightArrowCommand:(UIKeyCommand *)keyCommand {
    NSInteger newIndex = self.dataProvider.currentIndex + 1;
    [self showPhotoAtIndex:newIndex];
}

- (void)showPhotoAtIndex:(NSInteger)index {
    if ([self.dataProvider shouldUpdateCurrentIndexToIndex:index]) {
        [self.dataProvider updateCurrentIndexTo:index];
        [self reloadUI];
    }
}

- (BOOL)isPreviewingVersion {
    if ([[self presentingViewController] isKindOfClass:[MEGANavigationController class]]) {
        NSArray<UIViewController *>*viewcontrollers = [[self presentingViewController] childViewControllers];
        if ([viewcontrollers.lastObject isKindOfClass:[NodeVersionsViewController class]]) {
            return YES;
        }
    }
    return NO;
}

-(UIBarButtonItem *) slideshowButton {
    switch (self.displayMode) {
        case DisplayModeSharedItem:
        case DisplayModeCloudDrive:
            return self.centerToolbarItem;
        case DisplayModeAlbumLink:
        case DisplayModeNodeInsideFolderLink:
            return self.rightToolbarItem;
        default:
            return NULL;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self configLiveTextInterfaceFrom:self.imageViewsCache];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.tag == 1) {
        NSInteger newIndex = (scrollView.contentOffset.x + GapBetweenPages) / scrollView.frame.size.width;
        if ([self.dataProvider shouldUpdateCurrentIndexToIndex:newIndex]) {
            [self.dataProvider updateCurrentIndexTo:newIndex];
            [self resetZooms];
            [self reloadTitleWithCompletionHandler:^{}];
            [self activateSlideShowButtonWithBarButtonItem:[self slideshowButton]];
            [self updateMessageIdTo:newIndex];
        }
        
        [self configLiveTextLayout];
        
        [self startLiveTextAnalysisFrom:self.imageViewsCache];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.tag == 1) {
        if (self.pieChartView.alpha > 0.0f) {
            self.pieChartView.alpha = 0.0f;
        }
        
        NSUInteger newIndex = floor(scrollView.contentOffset.x + GapBetweenPages) / scrollView.frame.size.width;
        if ([self.dataProvider shouldUpdateCurrentIndexToIndex:newIndex]) {
            [self loadNearbyImagesFromIndex:newIndex];
        }
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self configLiveTextLayout];
    [self startLiveTextAnalysisFrom:self.imageViewsCache];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView.tag == 1) {
        return nil;
    } else {
        return scrollView.subviews.firstObject;
    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    if (scrollView.tag == 1) {
        return;
    }
    
    if (!self.interfaceHidden) {
        [self singleTapGesture:nil];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if (scrollView.tag == 1) {
        return;
    }
    
    [_imageViewsZoomCache setObject: @(scale) forKey:@(self.dataProvider.currentIndex)];
    
    [self resizeImageView:(UIImageView *)view];
    [self configLiveTextLayout];
    [self startLiveTextAnalysisFrom:self.imageViewsCache];
}

#pragma mark - Getting the images

-(void)configureNodeIntoImage:(MEGANode *) node nodeIndex:(NSUInteger) index {
    
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(index)];
    if(zoomableView == NULL) {
        return;
    }
    UIImageView * imageView = [zoomableView subviews][0];
    
    NSString *temporaryImagePath = [Helper pathWithOriginalNameForNode:node inSharedSandboxCacheDirectory:@"originalV3"];
    NSString *previewPath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"previewsV3"];
    BOOL isImageNode = [FileExtensionGroupOCWrapper verifyIsImage:node.name];
    
    if (isImageNode && [[NSFileManager defaultManager] fileExistsAtPath:temporaryImagePath]) {
        UIImage *placeHolderImage = [UIImage imageWithContentsOfFile:previewPath];
        
        [imageView sd_setImageWithURL:[NSURL fileURLWithPath: temporaryImagePath]
                     placeholderImage:placeHolderImage
                            completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            CGSize placeHolderImageSize = placeHolderImage.size;
            CGSize imageSize = image.size;
            
            // To avoid blurry image
            if (placeHolderImageSize.width * placeHolderImageSize.height > imageSize.width * imageSize.height) {
                [imageView setImage:placeHolderImage];
            }
            
            [self startLiveTextAnalysisFor:imageView in:index];
        }];
    } else {
        BOOL loadOriginalWithMobileData = [NSUserDefaults.standardUserDefaults boolForKey:MEGAUseMobileDataForPreviewingOriginalPhoto];
        if (([MEGAReachabilityManager isReachableViaWiFi] || loadOriginalWithMobileData) && isImageNode && node.size.longLongValue < MaxSizeToDownloadOriginal) {
            [self setupNode:node forImageView:imageView inIndex:index withMode:MEGAPhotoModeOriginal];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:previewPath]) {
            imageView.image = [UIImage imageWithContentsOfFile:previewPath];
        } else if (node.hasPreview) {
            if (([MEGAReachabilityManager isReachableViaWiFi] || loadOriginalWithMobileData)) {
                if (node.size.longLongValue > MinSizeToRequestThePreview) {
                    [self setupNode:node forImageView:imageView inIndex:index withMode:MEGAPhotoModePreview];
                }
            } else {
                [self setupNode:node forImageView:imageView inIndex:index withMode:MEGAPhotoModePreview];
            }
        } else {
            NSString *thumbnailPath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
                imageView.image = [UIImage imageWithContentsOfFile:thumbnailPath];
                [self startLiveTextAnalysisFor:imageView in:index];
            } else if (node.hasThumbnail && !isImageNode) {
                [self setupNode:node forImageView:imageView inIndex:index withMode:MEGAPhotoModeThumbnail];
            }
            if (isImageNode && ![node.name.pathExtension isEqualToString:@"gif"]) {
                [self setupNode:node forImageView:imageView inIndex:index withMode:MEGAPhotoModeOriginal];
            }
        }
        if ([node.name.pathExtension isEqualToString:@"gif"]) {
            [self setupNode:node forImageView:imageView inIndex:index withMode:MEGAPhotoModeOriginal];
        }
    }
    
    NSNumber* cachedZoomValue = [_imageViewsZoomCache objectForKey:@(index)];
    [zoomableView setZoomScale: (cachedZoomValue != nil ? [cachedZoomValue floatValue] : 1.0f)];
    zoomableView.maximumZoomScale = [self maximumZoomScaleWith:node zoomableView:zoomableView imageView:imageView];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
    doubleTap.numberOfTapsRequired = 2;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGesture:)];
    singleTap.numberOfTapsRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    if ([FileExtensionGroupOCWrapper verifyIsVideo:node.name]) {
        UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectMake((zoomableView.frame.size.width - self.playButtonSize) / 2, (zoomableView.frame.size.height - self.playButtonSize) / 2, self.playButtonSize, self.playButtonSize)];
        if (node.mnz_isPlayable) {
            [playButton setImage:[UIImage imageNamed:@"blackPlayButton"] forState:UIControlStateNormal];
        } else {
            [playButton setImage:[UIImage imageNamed:@"blackCrossedPlayButton"] forState:UIControlStateNormal];
        }
        playButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        playButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
        [playButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
        [zoomableView addSubview:playButton];
    } else {

        [zoomableView addGestureRecognizer:doubleTap];
    }
    [zoomableView addGestureRecognizer:singleTap];

}

- (void)loadNearbyImagesFromIndex:(NSUInteger)index {
    if (self.dataProvider.count > 0) {
        NSUInteger initialIndex = index == 0 ? 0 : index-1;
        NSUInteger finalIndex = index >= self.dataProvider.count - 1 ? self.dataProvider.count - 1 : index + 1;
        for (NSUInteger i = initialIndex; i <= finalIndex; i++) {
            if ([self.imageViewsCache objectForKey:@(i)]) {
                continue;
            }
            
            UIImageView *imageView = [self imageViewWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            
            UIScrollView *zoomableView = [[UIScrollView alloc] initWithFrame:CGRectMake(self.scrollView.frame.size.width * i, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
            zoomableView.minimumZoomScale = 1.0f;
            zoomableView.contentSize = imageView.bounds.size;
            zoomableView.delegate = self;
            zoomableView.showsHorizontalScrollIndicator = NO;
            zoomableView.showsVerticalScrollIndicator = NO;
            zoomableView.tag = 2;
            [zoomableView addSubview:imageView];

            [self.scrollView addSubview:zoomableView];
            
            [self.imageViewsCache setObject:zoomableView forKey:@(i)];
            
            [self loadNodeFor:i];
            
            [self configLiveTextLayout];
            
            if (i != self.dataProvider.currentIndex) {
                [imageView setImageLiveTextInterfaceHidden:true animated:false];
            }
        }
    }
}

- (void)setupNode:(MEGANode *)node forImageView:(UIImageView *)imageView inIndex:(NSUInteger)index withMode:(MEGAPhotoMode)mode addIndicators:(BOOL)shouldAddIndicators {
    [self removeActivityIndicatorsFromView:imageView];
    
    void (^requestCompletion)(MEGARequest *request) = ^(MEGARequest *request) {
        [UIView transitionWithView:imageView
                          duration:0.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            imageView.image = [UIImage imageWithContentsOfFile:request.file];
            [self resizeImageView:imageView];
        }
                        completion:nil];
        [self removeActivityIndicatorsFromView:imageView];
        [self startLiveTextAnalysisFor:imageView in:index];
    };
    
    void (^transferCompletion)(MEGATransfer *transfer) = ^(MEGATransfer *transfer) {
        [UIView transitionWithView:imageView
                          duration:0.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            
            imageView.image = [UIImage imageWithContentsOfFile:transfer.path];
            [self resizeImageView:imageView];

            if (self.dataProvider.currentIndex == index) {
                self.pieChartView.alpha = 0.0f;
                [self activateSlideShowButtonWithBarButtonItem:[self slideshowButton]];
            }
        }
                        completion:nil];
        
        [self removeActivityIndicatorsFromView:imageView];
        [self startLiveTextAnalysisFor:imageView in:index];
    };
    
    void (^transferProgress)(MEGATransfer *transfer) = ^(MEGATransfer *transfer) {
        if (self.dataProvider.currentIndex == index) {
            self.transferProgress = (double)transfer.transferredBytes / (double)transfer.totalBytes;
            [self.pieChartView reloadData];
            [self hideSlideShowButtonWithBarButtonItem:[self slideshowButton]];
            if (self.pieChartView.alpha < 1.0f) {
                [UIView animateWithDuration:0.2 animations:^{
                    self.pieChartView.alpha = 1.0f;
                }];
            }
        }
    };
    
    BOOL isImageNode = [FileExtensionGroupOCWrapper verifyIsImage:node.name];
    
    switch (mode) {
        case MEGAPhotoModeThumbnail:
            if (node.hasThumbnail) {
                MEGAGetThumbnailRequestDelegate *delegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:requestCompletion];
                NSString *path = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                [self.api getThumbnailNode:node destinationFilePath:path delegate:delegate];
            } else if (isImageNode) {
                [self setupNode:node forImageView:imageView inIndex:index withMode:MEGAPhotoModeOriginal addIndicators:false];
            }
            
            break;
            
        case MEGAPhotoModePreview:
            if (node.hasPreview) {
                MEGAGetPreviewRequestDelegate *delegate = [[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:requestCompletion];
                NSString *path = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"previewsV3"];
                [self.api getPreviewNode:node destinationFilePath:path delegate:delegate];
                [self addActivityIndicatorToView:imageView];
                [self activateSlideShowButtonWithBarButtonItem:[self slideshowButton]];
            } else if (isImageNode) {
                [self setupNode:node forImageView:imageView inIndex:index withMode:MEGAPhotoModeOriginal addIndicators:false];
            }
            
            break;
            
        case MEGAPhotoModeOriginal: {
            MEGAStartDownloadTransferDelegate *delegate =[[MEGAStartDownloadTransferDelegate alloc] initWithStart:nil progress:transferProgress completion:transferCompletion onError:nil];
            NSString *temporaryImagePath = [Helper pathWithOriginalNameForNode:node inSharedSandboxCacheDirectory:@"originalV3"];
            if (shouldAddIndicators) {
                [self addActivityIndicatorToView:imageView];
            }
            
            [MEGASdk.shared startDownloadNode:node localPath:temporaryImagePath fileName:nil appData:nil startFirst:NO cancelToken:nil collisionCheck: CollisionCheckFingerprint collisionResolution:CollisionResolutionNewWithN delegate:delegate];
            
            break;
        }
    }
}

- (void)setupNode:(MEGANode *)node forImageView:(UIImageView *)imageView inIndex:(NSUInteger)index withMode:(MEGAPhotoMode)mode {
    [self setupNode:node forImageView:imageView inIndex:index withMode:mode addIndicators:true];
}

- (UIActivityIndicatorView *)addActivityIndicatorToView:(UIView *)view {
    UIActivityIndicatorView *activityIndicator = UIActivityIndicatorView.mnz_init;
    activityIndicator.frame = CGRectMake((view.frame.size.width-activityIndicator.frame.size.width)/2, (view.frame.size.height-activityIndicator.frame.size.height)/2, activityIndicator.frame.size.width, activityIndicator.frame.size.height);
    [activityIndicator startAnimating];
    [view addSubview:activityIndicator];
    return activityIndicator;
}

- (void)removeActivityIndicatorsFromView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:UIActivityIndicatorView.class]) {
            [subview removeFromSuperview];
        }
    }
}

- (void)resizeImageView:(UIImageView *)imageView {
    if (imageView.image) {
        CGFloat imageRatio = imageView.image.size.height / imageView.image.size.width;
        CGFloat frameRatio = self.view.frame.size.height / self.view.frame.size.width;
        if (imageRatio != frameRatio) {
            CGRect frame = self.view.frame;
            if (imageRatio < frameRatio) {
                CGFloat newHeight = frame.size.width * imageRatio;
                frame.size.height = newHeight;
            } else {
                CGFloat newWidth = frame.size.height / imageRatio;
                frame.size.width = newWidth;
            }
            
            if ([imageView.superview isKindOfClass:UIScrollView.class]) {
                UIScrollView *zoomableView = (UIScrollView *)imageView.superview;
                CGFloat zoomScale = zoomableView.zoomScale;
                frame.size.width *= zoomScale;
                frame.size.height *= zoomScale;
            }
            
            imageView.frame = frame;
        }
    }
    
    [self correctOriginForView:imageView scaledAt:1.0f];
}

- (void)correctOriginForView:(UIView *)view scaledAt:(CGFloat)scale {
    UIView *zoomableView = view.superview;
    CGRect frame = view.frame;
    
    CGFloat zoomableViewOriginX = (zoomableView.frame.size.width - (view.frame.size.width * scale)) / 2;
    CGFloat zoomableViewOriginY = (zoomableView.frame.size.height - (view.frame.size.height * scale)) / 2;
    
    if (isnan(zoomableViewOriginX)) {
        MEGALogDebug(@"[Photo browser] Calculated scrollview origin x is Nan");
        zoomableViewOriginX = 0;
    }
    
    if (isnan(zoomableViewOriginY)) {
        MEGALogDebug(@"[Photo browser] Calculated scrollview origin y is Nan");
        zoomableViewOriginY = 0;
    }
    
    frame.origin.x = MAX(frame.origin.x + zoomableViewOriginX, 0);
    frame.origin.y = MAX(frame.origin.y + zoomableViewOriginY, 0);
    view.frame = frame;
}

#pragma mark - IBActions

- (IBAction)didPressCloseButton:(UIBarButtonItem *)sender {
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.dataProvider.currentIndex)];
    self.targetImageView = zoomableView.subviews.firstObject;
    [self toggleTransparentInterfaceForDismissal:YES];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didPressActionsButton:(UIBarButtonItem *)sender {
    
    [self didPressActionsButton:sender delegate:self completionHandler:^{ }];
}

- (IBAction)didPressAllMediasButton:(UIBarButtonItem *)sender {
    MEGAPhotoBrowserPickerViewController *pickerVC = [[UIStoryboard storyboardWithName:@"PhotoBrowser" bundle:[NSBundle bundleForClass:[self class]]] instantiateViewControllerWithIdentifier:@"MEGAPhotoBrowserPickerViewControllerID"];
    pickerVC.mediaNodes = self.dataProvider.allPhotos;
    pickerVC.delegate = self;
    pickerVC.api = self.api;
    pickerVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:pickerVC animated:YES completion:^{
        [TransfersWidgetViewController.sharedTransferViewController bringProgressToFrontKeyWindowIfNeeded];
    }];
}

- (IBAction)didPressLeftToolbarButton:(UIBarButtonItem *)sender {
    
    [self didPressLeftToolbarButton:sender completionHandler:^{ }];
}

- (IBAction)didPressImportbarButton:(UIBarButtonItem *)sender {
    MEGANode *node = self.dataProvider.currentPhoto;
    if (node == nil) {
        return;
    }
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [UIApplication.mnz_visibleViewController presentViewController:navigationController animated:YES completion:nil];
    
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.selectedNodesArray = [NSArray arrayWithObject:node];
    [browserVC setBrowserAction:BrowserActionImport];
    
}

- (IBAction)didPressSaveToPhotobarButton:(UIBarButtonItem *)sender {
    MEGANode *node = self.dataProvider.currentPhoto;
    if (node == nil) {
        return;
    }
    [self saveToPhotosWithNode:node];
}

- (IBAction)didPressForwardbarButton:(UIBarButtonItem *)sender {
    MEGANode *node = self.dataProvider.currentPhoto;
    if (node == nil) {
        return;
    }
    [node mnz_sendToChatInViewController:self];
}

- (IBAction)didPressExportFile:(UIBarButtonItem *)sender {
    [self didPressExportFile:sender completionHandler:^{ }];
}

- (void)presentActivityVC:(NSArray *)activityItems excludedActivityTypes:(NSArray<UIActivityType> *)excludedActivityTypes sender:(UIBarButtonItem *)sender {
    UIActivityViewController *activityViewController = [UIActivityViewController.alloc initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.excludedActivityTypes = excludedActivityTypes;
    activityViewController.popoverPresentationController.barButtonItem = sender;
    
    activityViewController.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        [self reloadUI];
    };
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)didPressRightToolbarButton:(UIBarButtonItem *)sender {
    [self didPressRightToolbarButton:sender completionHandler:^{}];
}

- (IBAction)didPressCenterToolbarButton:(UIBarButtonItem *)sender {
    [self didPressCenterToolbarButton:sender completionHandler:^{}];
}

#pragma mark - Gesture recognizers

- (void)panGesture:(UIPanGestureRecognizer *)panGestureRecognizer {
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.dataProvider.currentIndex)];
    if (zoomableView.zoomScale > 1.0f) {
        return;
    }
    self.targetImageView = zoomableView.subviews.firstObject;
    
    CGPoint touchPoint = [panGestureRecognizer translationInView:self.view];
    CGFloat verticalIncrement = touchPoint.y - self.panGestureInitialPoint.y;
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.panGestureInitialPoint = touchPoint;
            self.panGestureInitialFrame = self.targetImageView.frame;
            [self toggleTransparentInterfaceForDismissal:YES];
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGFloat initialHeight = CGRectGetHeight(self.panGestureInitialFrame);
            if (ABS(verticalIncrement) > 0 && initialHeight != 0) {
                CGFloat ratio = 1.0f - (0.3f * (ABS(verticalIncrement) / initialHeight));
                CGFloat horizontalPadding = CGRectGetWidth(self.panGestureInitialFrame) * (1.0f - ratio);
                self.targetImageView.frame = CGRectMake(self.panGestureInitialFrame.origin.x + (horizontalPadding / 2.0f),
                                                        self.panGestureInitialFrame.origin.y + (verticalIncrement / 2.0f),
                                                        CGRectGetWidth(self.panGestureInitialFrame) * ratio,
                                                        CGRectGetHeight(self.panGestureInitialFrame) * ratio);
            }
            
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (ABS(verticalIncrement) > 50.0f) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [UIView animateWithDuration:0.3 animations:^{
                    self.targetImageView.frame = self.panGestureInitialFrame;
                    [self toggleTransparentInterfaceForDismissal:NO];
                    self.interfaceHidden = NO;
                    self.panGestureInitialPoint = CGPointZero;
                } completion:^(BOOL finished) {
                    [self reloadUI];
                    self.targetImageView = nil;
                }];
            }
            
            break;
        }
            
        default:
            break;
    }
}

- (void)doubleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.dataProvider.currentIndex)];
    UIView *imageView = zoomableView.subviews.firstObject;
    if (zoomableView) {
        CGFloat newScale;
        if (imageView.frame.size.width < zoomableView.frame.size.width) {
            newScale = zoomableView.zoomScale > 1.0f ? 1.0f : zoomableView.frame.size.width / imageView.frame.size.width;
        } else {
            newScale = zoomableView.zoomScale > 1.0f ? 1.0f : 5.0f;
        }

        [_imageViewsZoomCache setObject: @(newScale) forKey:@(self.dataProvider.currentIndex)];

        [self scrollViewWillBeginZooming:zoomableView withView:zoomableView.subviews.firstObject];
        [UIView animateWithDuration:0.3 animations:^{
            if (newScale > 1.0f) {
                CGPoint tapPoint = [tapGestureRecognizer locationInView:tapGestureRecognizer.view];
                tapPoint = [imageView convertPoint:tapPoint fromView:tapGestureRecognizer.view];
                CGRect zoomRect = CGRectZero;
                zoomRect.size.width = imageView.frame.size.width / newScale;
                zoomRect.size.height = imageView.frame.size.height / newScale;
                zoomRect.origin.x = tapPoint.x - zoomRect.size.width / 2;
                zoomRect.origin.y = tapPoint.y - zoomRect.size.height / 2;
                [zoomableView zoomToRect:zoomRect animated:NO];
                if (!self.interfaceHidden) {
                    [self singleTapGesture:nil];
                }
            } else {
                zoomableView.zoomScale = newScale;
            }
            [self correctOriginForView:imageView scaledAt:newScale];
        } completion:^(BOOL finished) { }];
    }
}

- (void)singleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
    [UIView animateWithDuration:0.3 animations:^{
        if (self.isInterfaceHidden) {
            self.statusBarBackground.layer.opacity = self.navigationBar.layer.opacity = self.toolbar.layer.opacity = 1.0f;
            self.interfaceHidden = NO;
            self.view.backgroundColor = [self backgroundColor];
        } else {
            self.statusBarBackground.layer.opacity = self.navigationBar.layer.opacity = self.toolbar.layer.opacity = 0.0f;
            self.interfaceHidden = YES;
            self.view.backgroundColor = [self fullScreenBackgroundColor];
        }
        
        [self configLiveTextLayout];
        
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

#pragma mark - Targets

- (void)playVideo:(UIButton *)sender {
    [self playCurrentVideoWithCompletionHandler:^{}];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    if (CGRectIsEmpty(self.originFrame)) {
        return nil;
    } else {
        return [[MEGAPhotoBrowserAnimator alloc] initWithMode:MEGAPhotoBrowserAnimatorModePresent originFrame:self.originFrame targetImageView:self.targetImageView];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if (CGRectIsEmpty(self.originFrame)) {
        return nil;
    } else {
        return [[MEGAPhotoBrowserAnimator alloc] initWithMode:MEGAPhotoBrowserAnimatorModeDismiss originFrame:self.originFrame targetImageView:self.targetImageView];
    }
}

#pragma mark - PieChartViewDelegate

- (CGFloat)centerCircleRadius {
    return 0.0f;
}

#pragma mark - PieChartViewDataSource

- (int)numberOfSlicesInPieChartView:(PieChartView *)pieChartView {
    return 2;
}

- (UIColor *)pieChartView:(PieChartView *)pieChartView colorForSliceAtIndex:(NSUInteger)index {
    UIColor *color;
    switch (index) {
        case 0:
            color = [UIColor.whiteColor colorWithAlphaComponent:0.2];
            break;
            
        default:
            color = [UIColor.blackColor colorWithAlphaComponent:0.1];
            break;
    }
    return color;
}

- (double)pieChartView:(PieChartView *)pieChartView valueForSliceAtIndex:(NSUInteger)index {
    double valueForSlice;
    switch (index) {
        case 0:
            valueForSlice = self.transferProgress;
            break;
            
        default:
            valueForSlice = 1 - self.transferProgress;
            break;
    }
    
    return valueForSlice < 0 ? 0 : valueForSlice;
}

#pragma mark - NodeActionViewControllerDelegate

- (void)nodeAction:(NodeActionViewController *)nodeAction didSelect:(MegaNodeActionType)action for:(MEGANode *)node from:(id)sender {
    switch (action) {
        case MegaNodeActionTypeExportFile: {
            [self didPressExportFile:sender];
            break;
        }
            
        case MegaNodeActionTypeDownload:
            switch (self.displayMode) {
                case DisplayModeFileLink:
                    [self downloadFileLink];
                    break;
                    
                case DisplayModeChatAttachment:
                    [CancellableTransferRouterOCWrapper.alloc.init downloadChatNodes:@[node] messageId:self.messageId chatId:self.chatId presenter:self];
                    break;
                    
                default:
                    if (node != nil) {
                        [CancellableTransferRouterOCWrapper.alloc.init downloadNodes:@[node] presenter:self isFolderLink:self.api == MEGASdk.sharedFolderLink];
                    }
                    break;
            }
            break;
            
        case MegaNodeActionTypeInfo: {
            MEGANode *currentNode = self.dataProvider.currentPhoto;
            if (!currentNode) {
                return;
            }
            MEGANavigationController *nodeInfoNavigation = [NodeInfoViewController instantiateWithViewModel:[self createNodeInfoViewModelWithNode:node] delegate:self];
            [self presentViewController:nodeInfoNavigation animated:YES completion:nil];
            break;
        }
            
        case MegaNodeActionTypeFavourite: {
            [MEGASdk.shared setNodeFavourite:node favourite:!node.isFavourite];
            break;
        }
            
        case MegaNodeActionTypeLabel:
            [node mnz_labelActionSheetInViewController:self];
            break;
            
        case MegaNodeActionTypeCopy:
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
                [self presentViewController:navigationController animated:YES completion:nil];
                
                BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
                browserVC.selectedNodesArray = @[node];
                [browserVC setBrowserAction:BrowserActionCopy];
            }
            break;
            
        case MegaNodeActionTypeMove: {
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
            [self presentViewController:navigationController animated:YES completion:nil];
            
            BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
            browserVC.selectedNodesArray = @[node];
            if ([self.api accessLevelForNode:node] == MEGAShareTypeAccessOwner) {
                [browserVC setBrowserAction:BrowserActionMove];
            }
            break;
        }
            
        case MegaNodeActionTypeRename: {
            [node mnz_renameNodeInViewController:self completion:^(MEGARequest *request) {
                [self.dataProvider updatePhotoBy:request];
                [self reloadUI];
            }];
            break;
        }
            
        case MegaNodeActionTypeMoveToRubbishBin:
            [node mnz_askToMoveToTheRubbishBinInViewController:self];
            break;
            
        case MegaNodeActionTypeImport:
            [node mnz_fileLinkImportFromViewController:self isFolderLink:(self.displayMode == DisplayModeNodeInsideFolderLink)];
            break;
            
        case MegaNodeActionTypeRemove:
            [node mnz_removeInViewController:self completion:nil];
            break;
            
        case MegaNodeActionTypeSaveToPhotos:
            [self.viewModel trackAnalyticsSaveToDeviceMenuToolbarEvent];
            [self saveToPhotosWithNode:node];
            break;
            
        case MegaNodeActionTypeShareLink:
        case MegaNodeActionTypeManageLink: {
            if (self.displayMode == DisplayModeFileLink) {
                [self shareFileLink];
            } else {
                [self presentGetLinkFor:@[node]];
            }
            break;
        }
            
        case MegaNodeActionTypeRemoveLink:
            [self showRemoveLinkWarning:node];
            break;
            
        case MegaNodeActionTypeSendToChat:
            switch (self.displayMode) {
                case DisplayModeFileLink:
                    [self sendLinkToChat];
                    break;
                    
                default: {
                    [node mnz_sendToChatInViewController:self];
                    break;
                }
            }
            break;
            
        case MegaNodeActionTypeRestore:
            [node mnz_restore];
            break;
            
        case MegaNodeActionTypeViewVersions:
            [node mnz_showNodeVersionsInViewController:self];
            break;
            
        case MegaNodeActionTypeForward:
            [self didPressForwardbarButton:self.customActionsButton];
            break;
            
        case MegaNodeActionTypeViewInFolder:
            [self viewNodeInFolder:node];
            break;
            
        case MegaNodeActionTypeClear:
            [self clearNodeOnTransfers:node];
            [self dismissViewControllerAnimated:true completion:nil];
            break;
        case MegaNodeActionTypeHide:
            [self hideWithNode:node];
            break;
        case MegaNodeActionTypeUnhide:
            [self unhideWithNode:node];
            break;
        default:
            break;
    }
}

#pragma mark - NodeInfoViewControllerDelegate

- (void)nodeInfoViewController:(NodeInfoViewController *)nodeInfoViewController presentParentNode:(MEGANode *)node {
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.dataProvider.currentIndex)];
    self.targetImageView = zoomableView.subviews.firstObject;
    [self toggleTransparentInterfaceForDismissal:YES];
    
    UIViewController *presentingViewController = [self rootPresentingViewController];
    
    if (presentingViewController != nil) {
        [presentingViewController dismissViewControllerAnimated:YES completion:^{
            [node navigateToParentAndPresent];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            [node navigateToParentAndPresent];
        }];
    }
}

#pragma mark - MEGADelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self handleNodeUpdatesFromNodes:nodeList];
}

#pragma mark - Private methods.

- (UIImageView *)placeholderCurrentImageView {
    UIImageView *animatedImageView = [self currentImageViewFrom:self.imageViewsCache];
    
    UIImageView *imageview = UIImageView.new;
    imageview.backgroundColor = self.view.backgroundColor;
    imageview.image = animatedImageView.image;
    imageview.contentMode = animatedImageView.contentMode;
    
    return imageview;
}

- (nullable UIImageView *)placeholderPlayImageView {
    MEGANode *node = self.dataProvider.currentPhoto;
    if (node == nil) {
        return nil;
    }
    
    if ([FileExtensionGroupOCWrapper verifyIsVideo:node.name]) {
        UIImageView *imageview = [UIImageView.alloc initWithFrame:CGRectMake(0, 0, self.playButtonSize, self.playButtonSize)];
        imageview.image = [UIImage imageNamed: node.mnz_isPlayable ? @"blackPlayButton" : @"blackCrossedPlayButton"];
        
        return imageview;
    }
    
    return nil;
}

#pragma mark - Live Text

- (void)configLiveTextLayout {
    [self configLiveTextLayoutFrom:self.imageViewsCache
                 isInterfaceHidden:self.isInterfaceHidden
                      toolBarFrame:self.toolbar.frame];
}

@end
