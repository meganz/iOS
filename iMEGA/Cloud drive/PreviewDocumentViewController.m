
#import <QuickLook/QuickLook.h>

#import "PreviewDocumentViewController.h"
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
    if (![[NSFileManager defaultManager] createDirectoryAtPath:NSTemporaryDirectory() withIntermediateDirectories:YES attributes:nil error:&error]) {
        MEGALogError(@"Create directory at path");
    }

    NSString *localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:_node.name];
    [self.api startDownloadNode:_node localPath:localPath delegate:self];
    
    [self setTitle:_node.name];
    [_imageView setImage:[Helper infoImageForNode:self.node]];
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
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
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
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:previewDocumentTransfer.path];
    if (fileExists) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:previewDocumentTransfer.path error:&error]) {
            MEGALogError(@"Remove item at path: %@", error);
        }
    }
    
    previewDocumentTransfer = nil;
    
    if (([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)) {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller {
    //Avoid crash on iOS 7 and 8
    if (([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedDescending)) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    previewDocumentTransfer = transfer;
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [_activityIndicator stopAnimating];
    [_progressView setHidden:NO];
    float percentage = ([[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue] * 100);
    [_progressView setProgress:percentage];
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
    [self presentViewController:previewController animated:YES completion:^{
        [_progressView setHidden:YES];
    }];
}

@end
