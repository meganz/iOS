
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

@end

@implementation PreviewDocumentViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:self.node.name];
    [self.imageView setImage:[Helper infoImageForNode:self.node]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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
    } else if (!self.previewController) {
        [self loadPreviewWithName:self.node.name];
    }
    
   self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareAction:)];
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
        [self updatePreviewControllerFrameToSize:size];
    } completion:nil];
    
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Public

- (void)doneTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)updatePreviewControllerFrameToSize:(CGSize)size {
    self.previewController.view.frame = self.view.bounds;
}

- (void)loadPreviewWithName:(NSString *)name {
    self.previewController = [[QLPreviewController alloc] init];
    self.previewController.delegate = self;
    self.previewController.dataSource = self;
    self.previewController.title = name;
    self.previewController.view.frame = self.view.bounds;
    [self.view addSubview:self.previewController.view];
}

-(void)shareAction:(id)sender {
    UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[self.node] sender:sender];
    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    if (previewDocumentTransfer.path) {
        return [NSURL fileURLWithPath:previewDocumentTransfer.path];
    } else if (self.previewDocumentPath){
        return [NSURL fileURLWithPath:self.previewDocumentPath];
    }

    return nil;
}

#pragma mark - QLPreviewControllerDelegate

- (void)previewControllerWillDismiss:(QLPreviewController *)controller {
    previewDocumentTransfer = nil;
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
    
    [self loadPreviewWithName:transfer.fileName];
}

@end
