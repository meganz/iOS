
#import "MEGAPhotoBrowserViewController.h"

#import "UIImage+YYWebImage.h"
#import "PieChartView.h"
#import "SVProgressHUD.h"

#import "BrowserViewController.h"
#import "CloudDriveViewController.h"
#import "Helper.h"
#import "MainTabBarController.h"
#import "MEGAActivityItemProvider.h"
#import "CopyrightWarningViewController.h"
#import "MEGAGetPreviewRequestDelegate.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGAPhotoBrowserAnimator.h"
#import "MEGAPhotoBrowserPickerViewController.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStartDownloadTransferDelegate.h"
#import "NodeInfoViewController.h"
#import "SaveToCameraRollActivity.h"
#import "SendToViewController.h"

#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIDevice+MNZCategory.h"
#import "MEGA-Swift.h"

static const CGFloat GapBetweenPages = 10.0;

@interface MEGAPhotoBrowserViewController () <UIScrollViewDelegate, UIViewControllerTransitioningDelegate, MEGAPhotoBrowserPickerDelegate, PieChartViewDelegate, PieChartViewDataSource, NodeActionViewControllerDelegate, NodeInfoViewControllerDelegate, MEGADelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (weak, nonatomic) IBOutlet UIView *statusBarBackground;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet PieChartView *pieChartView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *customActionsButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftToolbarItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightToolbarItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *centerToolbarItem;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewTrailingConstraint;

@property (nonatomic) NSCache<NSNumber *, UIScrollView *> *imageViewsCache;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic) UIImageView *targetImageView;

@property (nonatomic) CGPoint panGestureInitialPoint;
@property (nonatomic) CGRect panGestureInitialFrame;
@property (nonatomic, getter=isInterfaceHidden) BOOL interfaceHidden;
@property (nonatomic) CGFloat playButtonSize;
@property (nonatomic) double transferProgress;
@property (nonatomic) BOOL needsReload;

@property (nonatomic) UIWindow *secondWindow;

@property (nonatomic) SendLinkToChatsDelegate *sendLinkDelegate;

@end

@implementation MEGAPhotoBrowserViewController

+ (MEGAPhotoBrowserViewController *)photoBrowserWithMediaNodes:(NSMutableArray<MEGANode *> *)mediaNodesArray api:(MEGASdk *)api displayMode:(DisplayMode)displayMode presentingNode:(MEGANode *)node preferredIndex:(NSUInteger)preferredIndex {
    NSUInteger index = preferredIndex;
    if (node) {
        for (NSUInteger i = 0; i < mediaNodesArray.count; i++) {
            MEGANode *mediaNode = [mediaNodesArray objectAtIndex:i];
            if (mediaNode.handle == node.handle) {
                index = i;
                break;
            }
        }
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PhotoBrowser" bundle:[NSBundle bundleForClass:[self class]]];
    MEGAPhotoBrowserViewController *photoBrowserVC = [storyboard instantiateViewControllerWithIdentifier:@"MEGAPhotoBrowserViewControllerID"];
    photoBrowserVC.api = api;
    photoBrowserVC.mediaNodes = mediaNodesArray;
    photoBrowserVC.preferredIndex = index;
    photoBrowserVC.displayMode = displayMode;
    
    return photoBrowserVC;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.modalPresentationCapturesStatusBarAppearance = YES;
    
    self.currentIndex = self.preferredIndex;
    
    self.panGestureInitialPoint = CGPointZero;
    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)]];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGesture:)];
    singleTap.numberOfTapsRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:singleTap];
    
    self.scrollView.delegate = self;
    self.scrollView.tag = 1;
    self.transitioningDelegate = self;
    self.playButtonSize = 100.0f;
    self.scrollViewTrailingConstraint.constant = GapBetweenPages;
    
    self.pieChartView.delegate = self;
    self.pieChartView.datasource = self;
    self.pieChartView.layer.cornerRadius = self.pieChartView.frame.size.width/2;
    self.pieChartView.layer.masksToBounds = YES;
    
    switch (self.displayMode) {
        case DisplayModeFileLink:
            self.leftToolbarItem.image = [UIImage imageNamed:@"import"];
            self.rightToolbarItem.image = [UIImage imageNamed:@"share"];
            self.centerToolbarItem.image = [UIImage imageNamed:@"saveToPhotos"];
            break;
            
        case DisplayModeSharedItem:
            [self.toolbar setItems:@[self.leftToolbarItem]];
            break;
            
        default:
            break;
    }
    
    self.closeBarButtonItem.title = AMLocalizedString(@"close", @"A button label.");
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
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
        if (!self.presentedViewController) {
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
        }
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
    [self airplayClear];
    self.secondWindow.hidden = YES;
    self.secondWindow = nil;
    
    [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [AppearanceManager forceNavigationBarUpdate:self.navigationBar traitCollection:self.traitCollection];
            [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
            
            [self updateAppearance];
        }
    }
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
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.mediaNodes.count, self.scrollView.frame.size.height);
    
    if (self.currentIndex >= self.mediaNodes.count) {
        MEGALogError(@"MEGAPhotoBrowserViewController tried to show the node at index %tu, with %tu items in the array of nodes", self.currentIndex, self.mediaNodes.count);
        if (self.mediaNodes.count > 0) {
            self.currentIndex = self.mediaNodes.count - 1;
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
    }
    
    [self loadNearbyImagesFromIndex:self.currentIndex];
    self.scrollView.contentOffset = CGPointMake(self.currentIndex * CGRectGetWidth(self.scrollView.frame), 0);
    [self reloadTitle];
    [self airplayDisplayCurrentImage];
    if ([self.delegate respondsToSelector:@selector(photoBrowser:didPresentNode:)]) {
        [self.delegate photoBrowser:self didPresentNode:[self.mediaNodes objectAtIndex:self.currentIndex]];
    }
    if ([self.delegate respondsToSelector:@selector(photoBrowser:didPresentNodeAtIndex:)]) {
        [self.delegate photoBrowser:self didPresentNodeAtIndex:self.currentIndex];
    }
}

- (void)reloadTitle {
    [self reloadTitleForIndex:self.currentIndex];
}

- (void)reloadTitleForIndex:(NSUInteger)newIndex {
    if (newIndex >= self.mediaNodes.count) {
        MEGALogError(@"MEGAPhotoBrowserViewController tried to show the node at index %tu, with %tu items in the array of nodes", newIndex, self.mediaNodes.count);
        return;
    }
    
    NSString *subtitle;
    
    switch (self.displayMode) {
        case DisplayModeFileLink:
            subtitle = AMLocalizedString(@"fileLink", @"Title for the file link view");
            
            break;
            
        default: {
            if (self.mediaNodes.count == 1) {
                subtitle = AMLocalizedString(@"indexOfTotalFile", @"Singular, please do not change the placeholders as they will be replaced by numbers. e.g. 1 of 1 file.");
            } else {
                subtitle = AMLocalizedString(@"indexOfTotalFiles", @"Plural, please do not change the placeholders as they will be replaced by numbers. e.g. 1 of 3 files.");
            }
            subtitle = [subtitle stringByReplacingOccurrencesOfString:@"%1$d" withString:[NSString stringWithFormat:@"%lu", (unsigned long)newIndex+1]];
            subtitle = [subtitle stringByReplacingOccurrencesOfString:@"%2$d" withString:[NSString stringWithFormat:@"%lu", (unsigned long)self.mediaNodes.count]];
            
            break;
        }
    }
    
    UILabel *titleLabel = [Helper customNavigationBarLabelWithTitle:[self.mediaNodes objectAtIndex:newIndex].name subtitle:subtitle color:UIColor.mnz_label];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor = 0.8f;
    self.navigationItem.titleView = titleLabel;
    [self.navigationItem.titleView sizeToFit];
}

- (void)resetZooms {
    for (NSUInteger i = 0; i < self.mediaNodes.count; i++) {
        UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(i)];
        if (zoomableView && zoomableView.zoomScale != 1.0f) {
            zoomableView.zoomScale = 1.0f;
            [self resizeImageView:(UIImageView *)zoomableView.subviews.firstObject];
        }
    }
}

- (void)toggleTransparentInterfaceForDismissal:(BOOL)transparent {
    self.view.backgroundColor = transparent ? UIColor.clearColor : UIColor.mnz_background;
    self.statusBarBackground.layer.opacity = self.navigationBar.layer.opacity = self.toolbar.layer.opacity = transparent ? 0.0f : 1.0f;
    
    // Toggle the play button:
    if (self.currentIndex >= self.mediaNodes.count) {
        MEGALogError(@"MEGAPhotoBrowserViewController tried to show the node at index %tu, with %tu items in the array of nodes", self.currentIndex, self.mediaNodes.count);
        return;
    }
    MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
    if (node.name.mnz_isVideoPathExtension) {
        UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.currentIndex)];
        if (zoomableView) {
            zoomableView.subviews.lastObject.hidden = transparent;
        }
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:^{
        if ([self.delegate respondsToSelector:@selector(didDismissPhotoBrowser:)]) {
            [self.delegate didDismissPhotoBrowser:self];
        }
        
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Private

- (void)shareFileLink {
    NSString *link = self.encryptedLink ? self.encryptedLink : self.publicLink;
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[link] applicationActivities:nil];
    [activityVC setExcludedActivityTypes:@[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop]];
    [activityVC.popoverPresentationController setBarButtonItem:self.rightToolbarItem];
    
    activityVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        [self reloadUI];
    };
    [self presentViewController:activityVC animated:YES completion:nil];
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
    self.statusBarBackground.backgroundColor = self.navigationBar.backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    
    [self reloadTitle];
    
    self.view.backgroundColor = UIColor.mnz_background;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.tag == 1) {
        NSInteger newIndex = (scrollView.contentOffset.x + GapBetweenPages) / scrollView.frame.size.width;
        if (newIndex != self.currentIndex && newIndex < self.mediaNodes.count) {
            self.currentIndex = newIndex;
            [self resetZooms];
            [self reloadTitle];
            [self airplayDisplayCurrentImage];
            if ([self.delegate respondsToSelector:@selector(photoBrowser:didPresentNode:)]) {
                [self.delegate photoBrowser:self didPresentNode:[self.mediaNodes objectAtIndex:self.currentIndex]];
            }
            if ([self.delegate respondsToSelector:@selector(photoBrowser:didPresentNodeAtIndex:)]) {
                [self.delegate photoBrowser:self didPresentNodeAtIndex:self.currentIndex];
            }
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.tag == 1) {
        if (self.pieChartView.alpha > 0.0f) {
            self.pieChartView.alpha = 0.0f;
        }
        
        NSUInteger newIndex = floor(scrollView.contentOffset.x + GapBetweenPages) / scrollView.frame.size.width;
        if (newIndex != self.currentIndex && newIndex < self.mediaNodes.count) {
            [self reloadTitleForIndex:newIndex];
            [self loadNearbyImagesFromIndex:newIndex];
        }
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView.tag == 1) {
        return nil;
    } else {
        return scrollView.subviews.firstObject;
    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    if (scrollView.tag != 1) {
        MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
        if (node.name.mnz_isImagePathExtension) {
            NSString *temporaryImagePath = [node mnz_temporaryPathForDownloadCreatingDirectories:NO];
            if (![[NSFileManager defaultManager] fileExistsAtPath:temporaryImagePath]) {
                [self setupNode:node forImageView:(YYAnimatedImageView *)view withMode:MEGAPhotoModeOriginal];
            }
            if (!self.interfaceHidden) {
                [self singleTapGesture:nil];
            }
        } else {
            scrollView.subviews.lastObject.hidden = YES;
        }
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if (scrollView.tag != 1) {
        MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
        if (node.name.mnz_isVideoPathExtension && scale == 1.0f) {
            scrollView.subviews.lastObject.hidden = NO;
        }
        [self resizeImageView:(UIImageView *)view];
    }
}

#pragma mark - Getting the images

- (void)loadNearbyImagesFromIndex:(NSUInteger)index {
    if (self.mediaNodes.count > 0) {
        NSUInteger initialIndex = index == 0 ? 0 : index-1;
        NSUInteger finalIndex = index >= self.mediaNodes.count - 1 ? self.mediaNodes.count - 1 : index + 1;
        for (NSUInteger i = initialIndex; i <= finalIndex; i++) {
            if ([self.imageViewsCache objectForKey:@(i)]) {
                continue;
            }
            
            YYAnimatedImageView *imageView = [[YYAnimatedImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            
            MEGANode *node = [self.mediaNodes objectAtIndex:i];
            NSString *temporaryImagePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"originalV3"];
            if (node.name.mnz_isImagePathExtension && [[NSFileManager defaultManager] fileExistsAtPath:temporaryImagePath]) {
                    imageView.yy_imageURL = [NSURL fileURLWithPath:temporaryImagePath];
            } else {
                NSString *previewPath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"previewsV3"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:previewPath]) {
                    imageView.image = [UIImage imageWithContentsOfFile:previewPath];
                } else if (node.hasPreview) {
                    [self setupNode:node forImageView:imageView withMode:MEGAPhotoModePreview];
                } else {
                    NSString *thumbnailPath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
                        imageView.image = [UIImage imageWithContentsOfFile:thumbnailPath];
                    } else if (node.hasThumbnail && !node.name.mnz_isImagePathExtension) {
                        [self setupNode:node forImageView:imageView withMode:MEGAPhotoModeThumbnail];
                    }
                    if (node.name.mnz_isImagePathExtension && ![node.name.pathExtension isEqualToString:@"gif"]) {
                        [self setupNode:node forImageView:imageView withMode:MEGAPhotoModeOriginal];
                    }
                }
                if ([node.name.pathExtension isEqualToString:@"gif"]) {
                    [self setupNode:node forImageView:imageView withMode:MEGAPhotoModeOriginal];
                }
            }
            
            UIScrollView *zoomableView = [[UIScrollView alloc] initWithFrame:CGRectMake(self.scrollView.frame.size.width * i, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
            zoomableView.minimumZoomScale = 1.0f;
            zoomableView.maximumZoomScale = node.name.mnz_isImagePathExtension ? 5.0f : 1.0f;
            zoomableView.zoomScale = 1.0f;
            zoomableView.contentSize = imageView.bounds.size;
            zoomableView.delegate = self;
            zoomableView.showsHorizontalScrollIndicator = NO;
            zoomableView.showsVerticalScrollIndicator = NO;
            zoomableView.tag = 2;
            [zoomableView addSubview:imageView];
            [self resizeImageView:imageView];

            if (node.name.mnz_isVideoPathExtension) {
                UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectMake((zoomableView.frame.size.width - self.playButtonSize) / 2, (zoomableView.frame.size.height - self.playButtonSize) / 2, self.playButtonSize, self.playButtonSize)];
                if (node.mnz_isPlayable) {
                    [playButton setImage:[UIImage imageNamed:@"blackPlayButton"] forState:UIControlStateNormal];
                } else {
                    [playButton setImage:[UIImage imageNamed:@"blackCrossedPlayButton"] forState:UIControlStateNormal];
                }
                playButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
                playButton.contentVerticalAlignment = UIControlContentHorizontalAlignmentFill;
                [playButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
                [zoomableView addSubview:playButton];
            }
            
            [self.scrollView addSubview:zoomableView];
            
            [self.imageViewsCache setObject:zoomableView forKey:@(i)];
        }
    }
}

- (void)setupNode:(MEGANode *)node forImageView:(YYAnimatedImageView *)imageView withMode:(MEGAPhotoMode)mode {
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
    };
    
    void (^transferCompletion)(MEGATransfer *transfer) = ^(MEGATransfer *transfer) {
        [UIView transitionWithView:imageView
                          duration:0.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            [imageView yy_setImageWithURL:[NSURL fileURLWithPath:transfer.path]
                              placeholder:imageView.image
                                  options:YYWebImageOptionProgressiveBlur
                               completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
                [self resizeImageView:imageView];
                }
             ];
            
            if (transfer.nodeHandle == [self.mediaNodes objectAtIndex:self.currentIndex].handle) {
                self.pieChartView.alpha = 0.0f;
            }
        }
                        completion:nil];
        [self removeActivityIndicatorsFromView:imageView];
    };
    
    void (^transferProgress)(MEGATransfer *transfer) = ^(MEGATransfer *transfer) {
        if (transfer.nodeHandle == [self.mediaNodes objectAtIndex:self.currentIndex].handle) {
            self.transferProgress = transfer.transferredBytes.doubleValue / transfer.totalBytes.doubleValue;
            [self.pieChartView reloadData];
            if (self.pieChartView.alpha < 1.0f) {
                [UIView animateWithDuration:0.2 animations:^{
                    self.pieChartView.alpha = 1.0f;
                }];
            }
        }
    };
    
    switch (mode) {
        case MEGAPhotoModeThumbnail:
            if (node.hasThumbnail) {
                MEGAGetThumbnailRequestDelegate *delegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:requestCompletion];
                NSString *path = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                [self.api getThumbnailNode:node destinationFilePath:path delegate:delegate];
            } else if (node.name.mnz_isImagePathExtension) {
                [self setupNode:node forImageView:imageView withMode:MEGAPhotoModeOriginal];
            }
            
            break;
            
        case MEGAPhotoModePreview:
            if (node.hasPreview) {
                MEGAGetPreviewRequestDelegate *delegate = [[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:requestCompletion];
                NSString *path = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previewsV3"];
                [self.api getPreviewNode:node destinationFilePath:path delegate:delegate];
                [self addActivityIndicatorToView:imageView];
            } else if (node.name.mnz_isImagePathExtension) {
                [self setupNode:node forImageView:imageView withMode:MEGAPhotoModeOriginal];
            }
            
            break;
            
        case MEGAPhotoModeOriginal: {
            MEGAStartDownloadTransferDelegate *delegate = [[MEGAStartDownloadTransferDelegate alloc] initWithProgress:transferProgress completion:transferCompletion onError:nil];
            NSString *temporaryImagePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"originalV3"];
            
            [MEGASdkManager.sharedMEGASdk startDownloadNode:[self.api authorizeNode:node] localPath:temporaryImagePath appData:nil delegate:delegate];

            break;
        }
    }
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
    frame.origin.x = MAX(frame.origin.x + (zoomableView.frame.size.width - (view.frame.size.width * scale)) / 2, 0);
    frame.origin.y = MAX(frame.origin.y + (zoomableView.frame.size.height - (view.frame.size.height * scale)) / 2, 0);
    view.frame = frame;
}

#pragma mark - IBActions

- (IBAction)didPressCloseButton:(UIBarButtonItem *)sender {
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.currentIndex)];
    self.targetImageView = zoomableView.subviews.firstObject;
    [self toggleTransparentInterfaceForDismissal:YES];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didPressActionsButton:(UIBarButtonItem *)sender {
    MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:[self.mediaNodes objectAtIndex:self.currentIndex].handle];
    if (node) {
        [self.mediaNodes setObject:node atIndexedSubscript:self.currentIndex];
    }
    
    NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:[self.mediaNodes objectAtIndex:self.currentIndex] delegate:self displayMode:self.displayMode isIncoming:NO sender:sender];
    [self presentViewController:nodeActions animated:YES completion:nil];
}

- (IBAction)didPressLeftToolbarButton:(UIBarButtonItem *)sender {
    MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
    
    switch (self.displayMode) {
        case DisplayModeFileLink:
            [node mnz_fileLinkImportFromViewController:self isFolderLink:NO];
            break;
            
        default: {
            MEGAPhotoBrowserPickerViewController *pickerVC = [[UIStoryboard storyboardWithName:@"PhotoBrowser" bundle:[NSBundle bundleForClass:[self class]]] instantiateViewControllerWithIdentifier:@"MEGAPhotoBrowserPickerViewControllerID"];
            pickerVC.mediaNodes = self.mediaNodes;
            pickerVC.delegate = self;
            pickerVC.api = self.api;
            pickerVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:pickerVC animated:YES completion:nil];
            
            break;
        }
    }
}

- (IBAction)didPressRightToolbarButton:(UIBarButtonItem *)sender {
    MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
    
    switch (self.displayMode) {
        case DisplayModeFileLink:
            [self shareFileLink];
            break;
            
        default: {
            UIActivityViewController *activityViewController;
            if (node.name.mnz_isVideoPathExtension) {
                activityViewController = [Helper activityViewControllerForNodes:@[node] sender:sender];
            } else {
                MEGAActivityItemProvider *activityItemProvider = [[MEGAActivityItemProvider alloc] initWithPlaceholderString:node.name node:node];
                NSMutableArray *activitiesMutableArray = [[NSMutableArray alloc] init];
                if (node.name.mnz_isImagePathExtension) {
                    SaveToCameraRollActivity *saveToCameraRollActivity = [[SaveToCameraRollActivity alloc] initWithNode:node api:self.api];
                    [activitiesMutableArray addObject:saveToCameraRollActivity];
                }
                activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[activityItemProvider] applicationActivities:activitiesMutableArray];
                activityViewController.excludedActivityTypes = @[UIActivityTypeSaveToCameraRoll, UIActivityTypeCopyToPasteboard];
                activityViewController.popoverPresentationController.barButtonItem = sender;
            }
            
            activityViewController.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
                [self reloadUI];
            };
            
            [self presentViewController:activityViewController animated:YES completion:nil];

            break;
        }
    }
}

- (IBAction)didPressCenterToolbarButton:(UIBarButtonItem *)sender {
    MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
    
    switch (self.displayMode) {
        case DisplayModeFileLink:
            [node mnz_saveToPhotosWithApi:self.api];
            break;
            
        default:
            break;
    }
}

#pragma mark - Gesture recognizers

- (void)panGesture:(UIPanGestureRecognizer *)panGestureRecognizer {
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.currentIndex)];
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
            if (ABS(verticalIncrement) > 0) {
                CGFloat ratio = 1.0f - (0.3f * (ABS(verticalIncrement) / self.panGestureInitialFrame.size.height));
                CGFloat horizontalPadding = self.panGestureInitialFrame.size.width * (1.0f - ratio);
                self.targetImageView.frame = CGRectMake(self.panGestureInitialFrame.origin.x + (horizontalPadding / 2.0f), self.panGestureInitialFrame.origin.y + (verticalIncrement / 2.0f), self.panGestureInitialFrame.size.width * ratio, self.panGestureInitialFrame.size.height * ratio);
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
    MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
    if (node.name.mnz_isVideoPathExtension) {
        return;
    }
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.currentIndex)];
    UIView *imageView = zoomableView.subviews.firstObject;
    if (zoomableView) {
        CGFloat newScale = zoomableView.zoomScale > 1.0f ? 1.0f : 5.0f;
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
        } completion:^(BOOL finished) {
            if (node.name.mnz_isVideoPathExtension && newScale == 1.0f) {
                zoomableView.subviews.lastObject.hidden = NO;
            }
        }];
    }
}

- (void)singleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
    [UIView animateWithDuration:0.3 animations:^{
        if (self.isInterfaceHidden) {
            self.statusBarBackground.layer.opacity = self.navigationBar.layer.opacity = self.toolbar.layer.opacity = 1.0f;
            self.view.backgroundColor = UIColor.mnz_background;
            self.interfaceHidden = NO;
        } else {
            self.view.backgroundColor = UIColor.mnz_background;
            self.statusBarBackground.layer.opacity = self.navigationBar.layer.opacity = self.toolbar.layer.opacity = 0.0f;
            self.interfaceHidden = YES;
        }
        
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

#pragma mark - Targets

- (void)playVideo:(UIButton *)sender {
    MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
    if (node.mnz_isPlayable) {
        if (MEGASdkManager.sharedMEGAChatSdk.mnz_existsActiveCall) {
            [Helper cannotPlayContentDuringACallAlert];
        } else {
            UIViewController *playerVC = [node mnz_viewControllerForNodeInFolderLink:(self.api == [MEGASdkManager sharedMEGASdkFolder]) fileLink:nil];
            [self presentViewController:playerVC animated:YES completion:nil];
        }
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"fileNotSupported", @"Alert title shown when users try to stream an unsupported audio/video file") message:AMLocalizedString(@"message_fileNotSupported", @"Alert message shown when users try to stream an unsupported audio/video file") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.view layoutIfNeeded];
            [self reloadUI];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - AirPlay

- (void)airplayDisplayCurrentImage {
    if ([[UIScreen screens] count] > 1) {
        if (!self.secondWindow) {
            UIScreen *secondScreen = [[UIScreen screens] objectAtIndex:1];
            CGRect screenBounds = secondScreen.bounds;
            self.secondWindow = [[UIWindow alloc] initWithFrame:screenBounds];
            self.secondWindow.screen = secondScreen;
            self.secondWindow.hidden = NO;
        }
        
        UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.currentIndex)];
        UIImageView *imageView = (UIImageView *)zoomableView.subviews.firstObject;
        UIImageView *airplayImageView = [[UIImageView alloc] initWithFrame:self.secondWindow.frame];
        airplayImageView.image = imageView.image;
        airplayImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self airplayClear];
        [self.secondWindow addSubview:airplayImageView];
    }
}

- (void)airplayClear {
    for (UIView *subview in self.secondWindow.subviews) {
        [subview removeFromSuperview];
    }
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

#pragma mark - MEGAPhotoBrowserPickerDelegate

- (void)updateCurrentIndexTo:(NSUInteger)newIndex {
    if (newIndex != self.currentIndex && newIndex < self.mediaNodes.count) {
        self.currentIndex = newIndex;
        self.needsReload = YES;
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
        case MegaNodeActionTypeShare: {
            
            switch (self.displayMode) {
                case DisplayModeFileLink:
                    [self shareFileLink];
                    break;
                    
                default: {
                    UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[node] sender:sender];
                    activityVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
                        [self reloadUI];
                    };
                    [self presentViewController:activityVC animated:YES completion:nil];
                    break;
                }
            }
            break;
        }
            
        case MegaNodeActionTypeDownload:
            switch (self.displayMode) {
                case DisplayModeFileLink:
                    [node mnz_fileLinkDownloadFromViewController:self isFolderLink:NO];
                    break;
                    
                default:
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
                    [node mnz_downloadNodeOverwriting:NO api:self.api];
                    break;
            }
            break;
            
        case MegaNodeActionTypeFileInfo: {
            UINavigationController *nodeInfoNavigation = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"NodeInfoNavigationControllerID"];
            NodeInfoViewController *nodeInfoVC = nodeInfoNavigation.viewControllers.firstObject;
            nodeInfoVC.node = [self.mediaNodes objectAtIndex:self.currentIndex];
            nodeInfoVC.nodeInfoDelegate = self;

            [self presentViewController:nodeInfoNavigation animated:YES completion:nil];
            break;
        }
            
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
                [self.mediaNodes replaceObjectAtIndex:self.currentIndex withObject:[self.api nodeForHandle:request.nodeHandle]];
                [self reloadUI];
            }];
            break;
        }
            
        case MegaNodeActionTypeMoveToRubbishBin:
            [node mnz_askToMoveToTheRubbishBinInViewController:self];
            break;
            
        case MegaNodeActionTypeImport:
            [node mnz_fileLinkImportFromViewController:self isFolderLink:NO];
            break;
            
        case MegaNodeActionTypeRemove:
            [node mnz_removeInViewController:self];
            break;
            
        case MegaNodeActionTypeSaveToPhotos:
            [node mnz_saveToPhotosWithApi:self.api];
            break;
            
        case MegaNodeActionTypeGetLink:
        case MegaNodeActionTypeManageLink: {
            if (MEGAReachabilityManager.isReachableHUDIfNot) {
                [CopyrightWarningViewController presentGetLinkViewControllerForNodes:@[node] inViewController:UIApplication.mnz_presentingViewController];
            }
            break;
        }
            
        case MegaNodeActionTypeRemoveLink:
            [node mnz_removeLink];
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
            
        default:
            break;
    }
}

#pragma mark - NodeInfoViewControllerDelegate

- (void)presentParentNode:(MEGANode *)node {
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.currentIndex)];
    self.targetImageView = zoomableView.subviews.firstObject;
    [self toggleTransparentInterfaceForDismissal:YES];

    [self dismissViewControllerAnimated:YES completion:^{
        [node navigateToParentAndPresent];
    }];
}

#pragma mark - MEGADelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if (nodeList) {
        NSArray<MEGANode *> *updatedNodesArray = nodeList.mnz_nodesArrayFromNodeList;
        NSMutableArray<MEGANode *> *nodesToRemoveArray = NSMutableArray.new;
        
        for (MEGANode *node in updatedNodesArray) {
            for (MEGANode *mediaNode in self.mediaNodes) {
                if (node.handle == mediaNode.handle) {
                    if ([node hasChangedType:MEGANodeChangeTypeRemoved] || [node hasChangedType:MEGANodeChangeTypeParent]) {
                        if ([self.mediaNodes indexOfObject:mediaNode] < self.currentIndex) {
                            self.currentIndex--;
                        }
                        [nodesToRemoveArray addObject:mediaNode];
                    }
                }
            }
        }
        
        if (nodesToRemoveArray.count) {
            [self.mediaNodes removeObjectsInArray:nodesToRemoveArray];
            if (self.mediaNodes.count) {
                if (self.currentIndex >= self.mediaNodes.count) {
                    self.currentIndex = self.mediaNodes.count - 1;
                }
                [self reloadUI];
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
    } else {
        [self reloadUI];
    }
}

#pragma mark - Private methods.

- (UIImageView *)placeholderCurrentImageView {
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:@(self.currentIndex)];
    YYAnimatedImageView *animatedImageView  = zoomableView.subviews.firstObject;
    
    UIImageView *imageview = UIImageView.new;
    imageview.backgroundColor = self.view.backgroundColor;
    imageview.image = animatedImageView.image;
    imageview.contentMode = animatedImageView.contentMode;
    
    return imageview;
}

- (nullable UIImageView *)placeholderPlayImageView {
    if (self.mediaNodes.count > self.currentIndex) {
        MEGANode *node = self.mediaNodes[self.currentIndex];
        if (node.name.mnz_isVideoPathExtension) {
            UIImageView *imageview = [UIImageView.alloc initWithFrame:CGRectMake(0, 0, self.playButtonSize, self.playButtonSize)];
     imageview.image = [UIImage imageNamed: node.mnz_isPlayable ? @"blackPlayButton" : @"blackCrossedPlayButton"];
            
            return imageview;
        }
    }

    return nil;
}

@end
