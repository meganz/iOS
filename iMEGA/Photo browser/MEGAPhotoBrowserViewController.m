
#import "MEGAPhotoBrowserViewController.h"

#import "Helper.h"
#import "MEGAGetPreviewRequestDelegate.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAStartDownloadTransferDelegate.h"

#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"

@interface MEGAPhotoBrowserViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic) NSMutableArray<MEGANode *> *mediaNodes;

@property (nonatomic) CGPoint panGestureInitialPoint;
@property (nonatomic, getter=isInterfaceHidden) BOOL interfaceHidden;
@property (nonatomic) NSUInteger currentIndex;

@end

@implementation MEGAPhotoBrowserViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mediaNodes = [[NSMutableArray<MEGANode *> alloc] init];
    
    for (MEGANode *node in self.nodesArray) {
        if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
            [self.mediaNodes addObject:node];
        }
    }
    
    self.panGestureInitialPoint = CGPointMake(0.0f, 0.0f);
    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)]];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)]];
    
    self.scrollView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadUI];
}

#pragma mark - UI

- (void)reloadUI {
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.mediaNodes.count, self.scrollView.frame.size.height);
    
    NSUInteger i = 0;
    for (MEGANode *node in self.mediaNodes) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.scrollView.frame.size.width * i, 0.0f, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        NSString *previewPath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previewsV3"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:previewPath]) {
            imageView.image = [UIImage imageWithContentsOfFile:previewPath];
        } else {
            [self setupNode:node forImageView:imageView withMode:MEGAPhotoModePreview];
        }
        [self.scrollView addSubview:imageView];
        if (node.handle == self.node.handle) {
            [self.scrollView scrollRectToVisible:imageView.frame animated:NO];
            self.currentIndex = i;
        }
        i++;
    }
    
    [self reloadTitle];
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
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.currentIndex = scrollView.contentOffset.x/scrollView.frame.size.width;
    [self reloadTitle];
}

#pragma mark - Getting the images

- (void)setupNode:(MEGANode *)node forImageView:(UIImageView *)imageView withMode:(MEGAPhotoMode)mode {
    void (^requestCompletion)(MEGARequest *request) = ^(MEGARequest *request) {
        imageView.image = [UIImage imageWithContentsOfFile:request.file];
    };
    void (^transferCompletion)(MEGATransfer *transfer) = ^(MEGATransfer *transfer) {
        imageView.image = [UIImage imageWithContentsOfFile:transfer.fileName];
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
                [self.api getThumbnailNode:node destinationFilePath:path delegate:delegate];
            } else {
                [self setupNode:node forImageView:imageView withMode:MEGAPhotoModeFull];
            }
            
            break;
            
        case MEGAPhotoModeFull: {
            MEGAStartDownloadTransferDelegate *delegate = [[MEGAStartDownloadTransferDelegate alloc] initWithCompletion:transferCompletion];
            NSString *offlineImagePath = [[NSFileManager defaultManager] downloadsDirectory];
            offlineImagePath = [offlineImagePath stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""];
            offlineImagePath = [offlineImagePath stringByAppendingPathComponent:[self.api escapeFsIncompatible:node.name]];
            [self.api startDownloadNode:node localPath:offlineImagePath appData:@"generate_fa" delegate:delegate];

            break;
        }
    }
}

#pragma mark - IBActions

- (IBAction)didPressCloseButton:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
            if (verticalIncrement > 0) {
                self.view.frame = CGRectMake(0.0f, verticalIncrement, self.view.frame.size.width, self.view.frame.size.height);
            }
            
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (verticalIncrement > 200.0f) {
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

- (void)tapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
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

@end
