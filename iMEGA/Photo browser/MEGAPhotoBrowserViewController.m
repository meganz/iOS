
#import "MEGAPhotoBrowserViewController.h"

#import "Helper.h"
#import "MEGAActivityItemProvider.h"
#import "MEGAGetPreviewRequestDelegate.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAPhotoBrowserAnimator.h"
#import "MEGAPhotoBrowserPickerViewController.h"
#import "MEGAStartDownloadTransferDelegate.h"
#import "SaveToCameraRollActivity.h"

#import "MEGANode+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIDevice+MNZCategory.h"

@interface MEGAPhotoBrowserViewController () <UIScrollViewDelegate, UIViewControllerTransitioningDelegate, MEGAPhotoBrowserPickerDelegate>

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic) NSMutableArray<MEGANode *> *mediaNodes;
@property (nonatomic) NSCache<NSString *, UIScrollView *> *imageViewsCache;
@property (nonatomic) NSUInteger currentIndex;

@property (nonatomic) CGPoint panGestureInitialPoint;
@property (nonatomic, getter=isInterfaceHidden) BOOL interfaceHidden;
@property (nonatomic) CGFloat playButtonSize;

@property (nonatomic) UIWindow *secondWindow;

@end

@implementation MEGAPhotoBrowserViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mediaNodes = [[NSMutableArray<MEGANode *> alloc] init];
    
    NSUInteger i = 0;
    for (MEGANode *node in self.nodesArray) {
        if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
            [self.mediaNodes addObject:node];
            if (node.handle == self.node.handle) {
                self.currentIndex = i;
            }
            i++;
        }
    }
    
    self.panGestureInitialPoint = CGPointMake(0.0f, 0.0f);
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view layoutIfNeeded];
    [self reloadUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view layoutIfNeeded];
    [self reloadUI];
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.view layoutIfNeeded];
        [self reloadUI];
    } completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self airplayClear];
    self.secondWindow.hidden = YES;
    self.secondWindow = nil;
}

#pragma mark - UI

- (void)reloadUI {
    for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }
    self.imageViewsCache = [[NSCache<NSString *, UIScrollView *> alloc] init];
    self.imageViewsCache.countLimit = 1000;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.mediaNodes.count, self.scrollView.frame.size.height);
    
    [self loadNearbyImagesFromIndex:self.currentIndex];
    MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
    UIScrollView *zoomableViewForInitialNode = [self.imageViewsCache objectForKey:node.base64Handle];
    [self.scrollView scrollRectToVisible:zoomableViewForInitialNode.frame animated:NO];
    [self reloadTitle];
    [self airplayDisplayCurrentImage];
}

- (void)reloadTitle {
    NSString *subtitle;
    if (self.mediaNodes.count == 1) {
        subtitle = AMLocalizedString(@"indexOfTotalFile", @"Singular, please do not change the placeholders as they will be replaced by numbers. e.g. 1 of 1 file.");
    } else {
        subtitle = AMLocalizedString(@"indexOfTotalFiles", @"Plural, please do not change the placeholders as they will be replaced by numbers. e.g. 1 of 3 files.");
    }
    subtitle = [subtitle stringByReplacingOccurrencesOfString:@"%1$d" withString:[NSString stringWithFormat:@"%lu", (unsigned long)self.currentIndex+1]];
    subtitle = [subtitle stringByReplacingOccurrencesOfString:@"%2$d" withString:[NSString stringWithFormat:@"%lu", (unsigned long)self.mediaNodes.count]];
    
    self.navigationItem.titleView = [Helper customNavigationBarLabelWithTitle:[self.mediaNodes objectAtIndex:self.currentIndex].name subtitle:subtitle];
    [self.navigationItem.titleView sizeToFit];
}

- (void)resetZooms {
    for (MEGANode *node in self.mediaNodes) {
        UIScrollView *zoomableView = [self.imageViewsCache objectForKey:node.base64Handle];
        if (zoomableView) {
            zoomableView.zoomScale = 1.0f;
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.tag == 1) {
        self.currentIndex = scrollView.contentOffset.x/scrollView.frame.size.width;
        [self resetZooms];
        [self reloadTitle];
        [self airplayDisplayCurrentImage];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.tag == 1) {
        CGFloat newIndexFloat = scrollView.contentOffset.x/scrollView.frame.size.width;
        NSUInteger newIndex = newIndexFloat < self.currentIndex ? floor(newIndexFloat) : ceil(newIndexFloat);
        if (newIndex != self.currentIndex) {
            self.currentIndex = newIndex;
            [self loadNearbyImagesFromIndex:self.currentIndex];
        }
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView.tag != 1) {
        return scrollView.subviews.firstObject;
    } else {
        return nil;
    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    if (scrollView.tag != 1) {
        MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
        if (node.name.mnz_isImagePathExtension) {
            NSString *temporaryImagePath = [self temporatyPathForNode:node];
            if (![[NSFileManager defaultManager] fileExistsAtPath:temporaryImagePath]) {
                [self setupNode:node forImageView:(UIImageView *)view withMode:MEGAPhotoModeFull];
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
    }
}

#pragma mark - Getting the images

- (void)loadNearbyImagesFromIndex:(NSUInteger)index {
    if (self.mediaNodes.count>0) {
        NSUInteger initialIndex = index == 0 ? 0 : index-1;
        NSUInteger finalIndex = index >= self.mediaNodes.count-1 ? self.mediaNodes.count-1 : index+1;
        for (NSUInteger i = initialIndex; i<=finalIndex; i++) {
            MEGANode *node = [self.mediaNodes objectAtIndex:i];
            if ([self.imageViewsCache objectForKey:node.base64Handle]) {
                continue;
            }
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            
            NSString *temporaryImagePath = [self temporatyPathForNode:node];
            if (node.name.mnz_isImagePathExtension && [[NSFileManager defaultManager] fileExistsAtPath:temporaryImagePath]) {
                imageView.image = [UIImage imageWithContentsOfFile:temporaryImagePath];
            } else {
                NSString *previewPath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previewsV3"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:previewPath]) {
                    imageView.image = [UIImage imageWithContentsOfFile:previewPath];
                } else {
                    NSString *thumbnailPath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
                        imageView.image = [UIImage imageWithContentsOfFile:thumbnailPath];
                    }
                    [self setupNode:node forImageView:imageView withMode:MEGAPhotoModePreview];
                }
            }
            
            UIScrollView *zoomableView = [[UIScrollView alloc] initWithFrame:CGRectMake(self.scrollView.frame.size.width * i, 0.0f, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
            zoomableView.minimumZoomScale = 1.0f;
            zoomableView.maximumZoomScale = 5.0f;
            zoomableView.zoomScale = 1.0f;
            zoomableView.contentSize = imageView.bounds.size;
            zoomableView.delegate = self;
            zoomableView.showsHorizontalScrollIndicator = NO;
            zoomableView.showsVerticalScrollIndicator = NO;
            zoomableView.tag = 2;
            [zoomableView addSubview:imageView];
            
            if (node.name.mnz_isVideoPathExtension) {
                UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectMake((imageView.frame.size.width-self.playButtonSize)/2, (imageView.frame.size.height-self.playButtonSize)/2, self.playButtonSize, self.playButtonSize)];
                [playButton setImage:[UIImage imageNamed:@"video_list"] forState:UIControlStateNormal];
                playButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
                playButton.contentVerticalAlignment = UIControlContentHorizontalAlignmentFill;
                [playButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
                [zoomableView addSubview:playButton];
            }
            
            [self.scrollView addSubview:zoomableView];
            
            [self.imageViewsCache setObject:zoomableView forKey:node.base64Handle];
        }
    }
}

- (void)setupNode:(MEGANode *)node forImageView:(UIImageView *)imageView withMode:(MEGAPhotoMode)mode {
    [self removeActivityIndicatorsFromView:imageView];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.frame = CGRectMake((imageView.frame.size.width-activityIndicator.frame.size.width)/2, (imageView.frame.size.height-activityIndicator.frame.size.height)/2, activityIndicator.frame.size.width, activityIndicator.frame.size.height);
    [activityIndicator startAnimating];
    [imageView addSubview:activityIndicator];

    void (^requestCompletion)(MEGARequest *request) = ^(MEGARequest *request) {
        imageView.image = [UIImage imageWithContentsOfFile:request.file];
        [activityIndicator removeFromSuperview];
    };
    void (^transferCompletion)(MEGATransfer *transfer) = ^(MEGATransfer *transfer) {
        imageView.image = [UIImage imageWithContentsOfFile:transfer.path];
        [self removeActivityIndicatorsFromView:imageView];
    };
    
    switch (mode) {
        case MEGAPhotoModeThumbnail:
            if([node hasThumbnail]) {
                MEGAGetThumbnailRequestDelegate *delegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:requestCompletion];
                NSString *path = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                [self.api getThumbnailNode:node destinationFilePath:path delegate:delegate];
            } else {
                [self setupNode:node forImageView:imageView withMode:MEGAPhotoModeFull];
            }
            
            break;
            
        case MEGAPhotoModePreview:
            if([node hasPreview]) {
                MEGAGetPreviewRequestDelegate *delegate = [[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:requestCompletion];
                NSString *path = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previewsV3"];
                [self.api getPreviewNode:node destinationFilePath:path delegate:delegate];
            } else {
                [self setupNode:node forImageView:imageView withMode:MEGAPhotoModeFull];
            }
            
            break;
            
        case MEGAPhotoModeFull: {
            MEGAStartDownloadTransferDelegate *delegate = [[MEGAStartDownloadTransferDelegate alloc] initWithCompletion:transferCompletion];
            NSString *temporaryImagePath = [self temporatyPathForNode:node];
            [self.api startDownloadNode:node localPath:temporaryImagePath appData:@"generate_fa" delegate:delegate];

            break;
        }
    }
}

- (void)removeActivityIndicatorsFromView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:UIActivityIndicatorView.class]) {
            [subview removeFromSuperview];
        }
    }
}

- (NSString *)temporatyPathForNode:(MEGANode *)node {
    NSString *nodeFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[node base64Handle]];
    NSString *nodeFilePath = [nodeFolderPath stringByAppendingPathComponent:node.name];
    
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:nodeFolderPath isDirectory:nil]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:nodeFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    return nodeFilePath;
}

#pragma mark - IBActions

- (IBAction)didPressCloseButton:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didPressThumbnailsButton:(UIBarButtonItem *)sender {
    MEGAPhotoBrowserPickerViewController *pickerVC = [[UIStoryboard storyboardWithName:@"MEGAPhotoBrowserViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"MEGAPhotoBrowserPickerViewControllerID"];
    pickerVC.mediaNodes = self.mediaNodes;
    pickerVC.delegate = self;
    pickerVC.api = self.api;
    [self presentViewController:pickerVC animated:YES completion:nil];
}

- (IBAction)didPressOpenIn:(UIBarButtonItem *)sender {
    MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
    
    MEGAActivityItemProvider *activityItemProvider = [[MEGAActivityItemProvider alloc] initWithPlaceholderString:node.name node:node];
    NSMutableArray *activitiesMutableArray = [[NSMutableArray alloc] init];
    SaveToCameraRollActivity *saveToCameraRollActivity = [[SaveToCameraRollActivity alloc] initWithNode:node];
    [activitiesMutableArray addObject:saveToCameraRollActivity];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[activityItemProvider] applicationActivities:activitiesMutableArray];
    
    [activityViewController setExcludedActivityTypes:@[UIActivityTypeSaveToCameraRoll, UIActivityTypeCopyToPasteboard]];
    activityViewController.popoverPresentationController.barButtonItem = sender;
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - Gesture recognizers

- (void)panGesture:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint touchPoint = [panGestureRecognizer translationInView:self.view];
    CGFloat verticalIncrement = touchPoint.y - self.panGestureInitialPoint.y;
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.panGestureInitialPoint = touchPoint;
            break;
            
        case UIGestureRecognizerStateChanged: {
            if (ABS(verticalIncrement) > 0) {
                self.view.frame = CGRectMake(0.0f, verticalIncrement, self.view.frame.size.width, self.view.frame.size.height);
            }
            
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (ABS(verticalIncrement) > 50.0f) {
                self.view.backgroundColor = [UIColor clearColor];
                self.backgroundView.backgroundColor = [UIColor clearColor];
                self.navigationBar.layer.opacity = self.toolbar.layer.opacity = 0.0f;
                self.navigationBar.hidden = self.toolbar.hidden = self.interfaceHidden = YES;
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [UIView animateWithDuration:0.3 animations:^{
                    self.view.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
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
    UIScrollView *zoomableView = [self.imageViewsCache objectForKey:node.base64Handle];
    if (zoomableView) {
        [self scrollViewWillBeginZooming:zoomableView withView:zoomableView.subviews.firstObject];
        [UIView animateWithDuration:0.3 animations:^{
            zoomableView.zoomScale = zoomableView.zoomScale > 1.0f ? 1.0f : 5.0f;
        } completion:^(BOOL finished) {
            [self scrollViewDidEndZooming:zoomableView withView:zoomableView.subviews.firstObject atScale:zoomableView.zoomScale];
        }];
    }
}

- (void)singleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
    [UIView animateWithDuration:0.3 animations:^{
        if (self.isInterfaceHidden) {
            self.view.backgroundColor = [UIColor clearColor];
            self.backgroundView.backgroundColor = [UIColor whiteColor];
            self.navigationBar.layer.opacity = self.toolbar.layer.opacity = 1.0f;
            self.navigationBar.hidden = self.toolbar.hidden = self.interfaceHidden = NO;
        } else {
            self.view.backgroundColor = [UIColor blackColor];
            self.backgroundView.backgroundColor = [UIColor blackColor];
            self.navigationBar.layer.opacity = self.toolbar.layer.opacity = 0.0f;
            self.navigationBar.hidden = self.toolbar.hidden = self.interfaceHidden = YES;
        }
    }];
}

#pragma mark - Targets

- (void)playVideo:(UIButton *)sender {
    MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
    UIViewController *playerVC = [node mnz_viewControllerForNodeInFolderLink:(self.api==[MEGASdkManager sharedMEGASdkFolder])];
    [self presentViewController:playerVC animated:YES completion:nil];
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
        MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
        UIScrollView *zoomableView = [self.imageViewsCache objectForKey:node.base64Handle];
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
    if (!CGRectIsEmpty(self.originFrame)) {
        return [[MEGAPhotoBrowserAnimator alloc] initWithMode:MEGAPhotoBrowserAnimatorModePresent originFrame:self.originFrame];
    } else {
        return nil;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    // TODO: To properly dismiss the view controller with the same animation as in the presentation, the previous
    // view controller should scroll to the node corresponding to the node at the current index in this view
    // controller, and then send its frame here. The code to animate de dismissal is the same as in the preious
    // method, with MEGAPhotoBrowserAnimatorModeDismiss mode.
    return nil;
}

#pragma mark - MEGAPhotoBrowserPickerDelegate

- (void)updateCurrentIndexTo:(NSUInteger)newIndex {
    self.currentIndex = newIndex;
    [self loadNearbyImagesFromIndex:self.currentIndex];
    MEGANode *node = [self.mediaNodes objectAtIndex:self.currentIndex];
    UIScrollView *zoomableViewForInitialNode = [self.imageViewsCache objectForKey:node.base64Handle];
    [self.scrollView scrollRectToVisible:zoomableViewForInitialNode.frame animated:NO];
    [self reloadTitle];
    [self airplayDisplayCurrentImage];
}

@end
