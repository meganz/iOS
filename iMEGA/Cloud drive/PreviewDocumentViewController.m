
#import <QuickLook/QuickLook.h>

#import "PreviewDocumentViewController.h"
#import "Helper.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"

@interface PreviewDocumentViewController () <QLPreviewControllerDataSource, QLPreviewControllerDelegate, MEGATransferDelegate> {
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
    
    NSString *localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:_node.name];
    [[MEGASdkManager sharedMEGASdk] startDownloadNode:_node localPath:localPath delegate:self];
    
    [self setTitle:_node.name];
    [_imageView setImage:[Helper infoImageForNode:self.node]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController && previewDocumentTransfer) {
        [[MEGASdkManager sharedMEGASdk] cancelTransfer:previewDocumentTransfer];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return [NSURL fileURLWithPath:previewDocumentTransfer.path];
}

#pragma mark - QLPreviewControllerDelegate

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

- (void)previewControllerWillDismiss:(QLPreviewController *)controller {
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:previewDocumentTransfer.path];
    if (fileExists) {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:previewDocumentTransfer.path error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove temp document error: %@", error]];
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
    previewDocumentTransfer = nil;
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
    [previewController setTitle:transfer.fileName];
    [self presentViewController:previewController animated:YES completion:nil];
}

@end
