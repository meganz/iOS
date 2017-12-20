#import "PreviewDocumentViewController.h"

#import <QuickLook/QuickLook.h>

#import "Helper.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"

@interface PreviewDocumentViewController () <UIViewControllerTransitioningDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate, MEGATransferDelegate> {
    MEGATransfer *previewDocumentTransfer;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@end

@implementation PreviewDocumentViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSError * error = nil;
    NSString *nodeFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.node base64Handle]];
    NSString *nodeFilePath = [nodeFolderPath stringByAppendingPathComponent:self.node.name];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:nodeFolderPath isDirectory:nil]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:nodeFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:nodeFilePath isDirectory:nil]) {
        [self.api startDownloadNode:self.node localPath:nodeFilePath delegate:self];
    }
    
    [self setTitle:self.node.name];
    [self.imageView setImage:[Helper infoImageForNode:self.node]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController && previewDocumentTransfer) {
        [self.api cancelTransfer:previewDocumentTransfer];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    if ([presented isKindOfClass:[QLPreviewController class]]) {
        return [[MEGAQLPreviewControllerTransitionAnimator alloc] init];
    }
    
    return nil;
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    if (previewDocumentTransfer.path != nil) {
        return [NSURL fileURLWithPath:previewDocumentTransfer.path];
    }

    return nil;
}

#pragma mark - QLPreviewControllerDelegate

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

- (void)previewControllerWillDismiss:(QLPreviewController *)controller {
    previewDocumentTransfer = nil;
    
    if (@available(iOS 9.0, *)) {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller {
    if (@available(iOS 9.0, *)) {} else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    previewDocumentTransfer = transfer;
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [self.activityIndicator stopAnimating];
    [self.progressView setHidden:NO];
    float percentage = ([[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue] * 100);
    [self.progressView setProgress:percentage];
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (error.type != MEGAErrorTypeApiOk) {
        return;
    }
    
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    [previewController setDelegate:self];
    [previewController setDataSource:self];
    [previewController setTransitioningDelegate:self];
    [previewController setTitle:transfer.fileName];
    [self addChildViewController:previewController];
    CGFloat y = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
    previewController.view.frame = CGRectMake(0.0f, y, self.view.frame.size.width, self.view.frame.size.height - y);
    [self.view addSubview:previewController.view];
}

@end
