
#import "PreviewDocumentViewController.h"

#import <QuickLook/QuickLook.h>
#import <PDFKit/PDFKit.h>

#import "SVProgressHUD.h"

#import "Helper.h"
#import "CustomActionViewController.h"
#import "NodeInfoViewController.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "BrowserViewController.h"
#import "CloudDriveTableViewController.h"
#import "MainTabBarController.h"
#import "SearchInPdfViewController.h"

#import "MEGANode+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

@interface PreviewDocumentViewController () <QLPreviewControllerDataSource, QLPreviewControllerDelegate, MEGATransferDelegate, UICollectionViewDelegate, UICollectionViewDataSource, CustomActionViewControllerDelegate, NodeInfoViewControllerDelegate, SearchInPdfViewControllerProtocol> {
    MEGATransfer *previewDocumentTransfer;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet PDFView *pdfView NS_AVAILABLE_IOS(11.0);
@property (weak, nonatomic) IBOutlet UIBarButtonItem *thumbnailBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *openInBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) QLPreviewController *previewController;
@property (nonatomic) NSString *nodeFilePath;
@property (nonatomic) NSCache<NSNumber *, UIImage *> *thumbnailCache;
@property (nonatomic) BOOL thumbnailsPopulated;
@property (nonatomic) PDFSelection *searchedItem NS_AVAILABLE_IOS(11.0);

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
    if (@available(iOS 11.0, *)) {
        NSURL *url = [self documentUrl];
        if ([url.pathExtension isEqualToString:@"pdf"]) {
            [self loadPdfKit:url];
        } else {
            [self loadQLController];
        }
    } else {
        [self loadQLController];
    }
}

- (NSURL *)documentUrl {
    if (previewDocumentTransfer.path) {
        return [NSURL fileURLWithPath:previewDocumentTransfer.path];
    } else if (self.node){
        return [NSURL fileURLWithPath:self.nodeFilePath];
    } else {
        self.title = [self.filesPathsArray objectAtIndex:self.nodeFileIndex].lastPathComponent;
        return [NSURL fileURLWithPath:[self.filesPathsArray objectAtIndex:self.nodeFileIndex]];
    }
}

- (void)loadQLController {
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

- (IBAction)thumbnailTapped:(id)sender {
    if (self.collectionView.hidden) {
        if (!self.thumbnailsPopulated) {
            [self.collectionView reloadData];
            self.thumbnailsPopulated = YES;
        }
        self.collectionView.hidden = NO;
        self.thumbnailBarButtonItem.image = [UIImage imageNamed:@"fullsize"];
    } else {
        self.collectionView.hidden = YES;
        self.thumbnailBarButtonItem.image = [UIImage imageNamed:@"thumbnailsView"];
    }
}

- (IBAction)actionsTapped:(UIBarButtonItem *)sender {
    CustomActionViewController *actionController = [[CustomActionViewController alloc] init];
    actionController.node = self.node;
    actionController.actionDelegate = self;
    if ([[UIDevice currentDevice] iPadDevice]) {
        actionController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popController = [actionController popoverPresentationController];
        popController.delegate = actionController;
        popController.barButtonItem = sender;
    } else {
        actionController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    
    [self presentViewController:actionController animated:YES completion:nil];
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

#pragma mark - CustomActionViewControllerDelegate

- (void)performAction:(MegaNodeActionType)action inNode:(MEGANode *)node fromSender:(id)sender{
    switch (action) {
        case MegaNodeActionTypeShare: {
            UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[self.node] sender:sender];
            [self presentViewController:activityVC animated:YES completion:nil];
            break;
        }
            
        case MegaNodeActionTypeDownload:
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
            [node mnz_downloadNodeOverwriting:NO];
            break;
            
        case MegaNodeActionTypeFileInfo: {
            UINavigationController *nodeInfoNavigation = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"NodeInfoNavigationControllerID"];
            NodeInfoViewController *nodeInfoVC = nodeInfoNavigation.viewControllers.firstObject;
            nodeInfoVC.node = node;
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
                [self setTitle:request.name];
            }];
            break;
        }
            
        case MegaNodeActionTypeMoveToRubbishBin:
            [node mnz_moveToTheRubbishBinInViewController:self];
            break;
            
        default:
            break;
    }
}

#pragma mark - NodeInfoViewControllerDelegate

- (void)presentParentNode:(MEGANode *)node {
    [self dismissViewControllerAnimated:YES completion:^{
        UIViewController *visibleViewController = [UIApplication mnz_visibleViewController];
        if ([visibleViewController isKindOfClass:MainTabBarController.class]) {
            NSArray *parentTreeArray = node.mnz_parentTreeArray;
            
            UINavigationController *navigationController = (UINavigationController *)((MainTabBarController *)visibleViewController).viewControllers[((MainTabBarController *)visibleViewController).selectedIndex];
            [navigationController popToRootViewControllerAnimated:NO];
            
            for (MEGANode *node in parentTreeArray) {
                CloudDriveTableViewController *cloudDriveTVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
                cloudDriveTVC.parentNode = node;
                [navigationController pushViewController:cloudDriveTVC animated:NO];
            }
            
            switch (node.type) {
                case MEGANodeTypeFolder:
                case MEGANodeTypeRubbish: {
                    CloudDriveTableViewController *cloudDriveTVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
                    cloudDriveTVC.parentNode = node;
                    [navigationController pushViewController:cloudDriveTVC animated:NO];
                    break;
                }
                    
                default:
                    break;
            }
            
        }
    }];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (IBAction)searchTapped:(id)sender {
    self.collectionView.hidden = YES;
    UINavigationController *searchInPdfNavigation = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"SearchInPdfNavigationID"];
    SearchInPdfViewController *searchInPdfVC = searchInPdfNavigation.viewControllers.firstObject;
    searchInPdfVC.pdfDocument = self.pdfView.document;
    searchInPdfVC.delegate = self;
    [self presentViewController:searchInPdfNavigation animated:YES completion:nil];
}

- (void)loadPdfKit:(NSURL *)url {
    if (!self.pdfView.document) {
        self.pdfView.hidden = NO;
        self.activityIndicator.hidden = YES;
        self.progressView.hidden = YES;
        self.imageView.hidden = YES;
        
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [self setToolbarItems:@[self.thumbnailBarButtonItem, flexibleItem, self.searchBarButtonItem, flexibleItem, self.openInBarButtonItem] animated:YES];
        [self.navigationController setToolbarHidden:NO animated:YES];
        self.navigationItem.rightBarButtonItem = self.node ? self.moreBarButtonItem : nil;
        
        self.pdfView.autoScales = YES;
        self.pdfView.document = [[PDFDocument alloc] initWithURL:url];
        
        [self.pdfView goToFirstPage:nil];
    }
}

#pragma mark - CollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect pageRect = CGPDFPageGetBoxRect([self.pdfView.document pageAtIndex:indexPath.item].pageRef, kCGPDFMediaBox);
    float thumbnailWidth = (self.collectionView.frame.size.width - 60) / 3;
    float ratio = pageRect.size.width / thumbnailWidth;
    return CGSizeMake(thumbnailWidth, pageRect.size.height / ratio);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.pdfView setScaleFactor:self.pdfView.scaleFactorForSizeToFit];
    [self.pdfView goToPage:[self.pdfView.document pageAtIndex:indexPath.item]];
    self.thumbnailBarButtonItem.image = [UIImage imageNamed:@"thumbnailsView"];
    self.collectionView.hidden = YES;
}

#pragma mark - CollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.pdfView.document.pageCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"ThumbnailPageID" forIndexPath:indexPath];
    UIImageView *imageView = [cell viewWithTag:100];
    UILabel *pageLabel = [cell viewWithTag:1];
    pageLabel.text = [NSString stringWithFormat:@"%ld", (long)indexPath.item + 1];
    if ([self.thumbnailCache objectForKey:[NSNumber numberWithInteger:indexPath.item]]) {
        imageView.image = [self.thumbnailCache objectForKey:[NSNumber numberWithInteger:indexPath.item]];
    } else {
        PDFPage *page = [self.pdfView.document pageAtIndex:indexPath.item];
        imageView.image = [page thumbnailOfSize:CGSizeMake(100, 100) forBox:kPDFDisplayBoxMediaBox];
        [self.thumbnailCache setObject:imageView.image forKey:[NSNumber numberWithInteger:indexPath.item]];
    }
    
    return cell;
}

#pragma mark - SearchInPdfViewControllerProtocol

- (void)didSelectSearchResult:(PDFSelection *)result {
    result.color = UIColor.yellowColor;
    [self.pdfView setCurrentSelection:result];
    [self.pdfView setScaleFactor:self.pdfView.scaleFactorForSizeToFit];
    [self.pdfView goToPage:result.pages[0]];
}

#pragma clang diagnostic pop

@end
