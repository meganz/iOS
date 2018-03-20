
#import "PreviewDocumentViewController.h"

#import <QuickLook/QuickLook.h>

#import "Helper.h"

@interface PreviewDocumentViewController () <UIViewControllerTransitioningDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate, MEGATransferDelegate> {
    MEGATransfer *previewDocumentTransfer;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic) QLPreviewController *previewController;
@property (nonatomic) NSString *nodeFilePath;

@end

@implementation PreviewDocumentViewController

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configureNavigation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.filesPathsArray) {
        [self loadPreview];
    } else {
        NSError * error = nil;
        NSString *nodeFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.node base64Handle]];
        self.nodeFilePath = [nodeFolderPath stringByAppendingPathComponent:self.node.name];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:nodeFolderPath isDirectory:nil]) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:nodeFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                MEGALogError(@"Create directory at path failed with error: %@", error);
            }
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.nodeFilePath isDirectory:nil]) {
            [self.api startDownloadNode:self.node localPath:self.nodeFilePath delegate:self];
        } else if (!self.previewController) {
            [self loadPreview];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController && previewDocumentTransfer) {
        [self.api cancelTransfer:previewDocumentTransfer];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.previewController.view.frame = self.view.bounds;
    } completion:nil];
    
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)configureNavigation {
    [self setTitle:self.node.name];
    [self.imageView setImage:[Helper infoImageForNode:self.node]];
    self.navigationController.navigationBar.barTintColor = [UIColor colorFromHexString:@"FCFCFC"];
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor mnz_black333333],
       NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:17]}];
    self.navigationController.navigationBar.tintColor = [UIColor mnz_redFF4D52];
}

- (void)loadPreview {
    self.previewController = [[QLPreviewController alloc] init];
    self.previewController.delegate = self;
    self.previewController.dataSource = self;
    self.previewController.view.frame = self.view.bounds;
    
    if (self.filesPathsArray) {
        self.title = [self.filesPathsArray objectAtIndex:self.nodeFileIndex].lastPathComponent;
        [self.previewController setCurrentPreviewItemIndex:self.nodeFileIndex];
        [self addObserver:self forKeyPath:@"self.previewController.title" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    [self.view addSubview:self.previewController.view];
}

- (IBAction)shareAction:(id)sender {
    NSString *filePath = self.filesPathsArray ? [self.filesPathsArray objectAtIndex:self.previewController.currentPreviewItemIndex] : self.nodeFilePath;
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[filePath.lastPathComponent, [NSURL fileURLWithPath:filePath]] applicationActivities:nil];
    activityVC.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)doneTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"self.previewController.title"]) {
        UILabel *titleLabel = [Helper customNavigationBarLabelWithTitle:[self.filesPathsArray objectAtIndex:self.previewController.currentPreviewItemIndex].lastPathComponent subtitle:self.previewController.title color:[UIColor mnz_black333333]];
        titleLabel.adjustsFontSizeToFitWidth = YES;
        titleLabel.minimumScaleFactor = 0.8f;
        self.navigationItem.titleView = titleLabel;
        [self.navigationItem.titleView sizeToFit];
    }
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    if (self.filesPathsArray) {
        return self.filesPathsArray.count;
    }
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    if (self.filesPathsArray) {
        return [NSURL fileURLWithPath:[self.filesPathsArray objectAtIndex:index]];
    } else {
        if (previewDocumentTransfer.path) {
            return [NSURL fileURLWithPath:previewDocumentTransfer.path];
        } else {
            return [NSURL fileURLWithPath:self.nodeFilePath];
        }
    }
}

#pragma mark - QLPreviewControllerDelegate

- (void)previewControllerWillDismiss:(QLPreviewController *)controller {
    previewDocumentTransfer = nil;
    if (self.filesPathsArray) {
        [self removeObserver:self forKeyPath:@"self.previewController.title"];
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    previewDocumentTransfer = transfer;
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [self.activityIndicator stopAnimating];
    [self.progressView setHidden:NO];
    float percentage = (transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue * 100);
    [self.progressView setProgress:percentage];
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (error.type != MEGAErrorTypeApiOk) {
        return;
    }
    
    [self loadPreview];
}

@end
