
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
#import "CloudDriveViewController.h"
#import "MainTabBarController.h"
#import "SearchInPdfViewController.h"

#import "MEGANode+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGAQLPreviewController.h"
#import "MEGA-Swift.h"
#import "UIView+MNZCategory.h"

@interface PreviewDocumentViewController () <QLPreviewControllerDataSource, QLPreviewControllerDelegate, MEGATransferDelegate, UICollectionViewDelegate, UICollectionViewDataSource, CustomActionViewControllerDelegate, NodeInfoViewControllerDelegate, SearchInPdfViewControllerProtocol, UIGestureRecognizerDelegate> {
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigation];
    
    self.moreBarButtonItem.accessibilityLabel = AMLocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.filesPathsArray) {
        [self loadPreview];
    } else {
        NSError * error = nil;
        NSString *nodeFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.node base64Handle]];
        self.nodeFilePath = [nodeFolderPath stringByAppendingPathComponent:self.node.name];
        
        if ([[NSFileManager defaultManager] createDirectoryAtPath:nodeFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            [MEGASdkManager.sharedMEGASdk startDownloadTopPriorityWithNode:[self.api authorizeNode:self.node] localPath:self.nodeFilePath appData:nil delegate:self];
        } else {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (previewDocumentTransfer) {
        [MEGASdkManager.sharedMEGASdk cancelTransfer:previewDocumentTransfer];
    }
    
    if (@available(iOS 11.0, *)) {
        if (!self.pdfView.hidden) {
            CGPDFPageRef pageRef = self.pdfView.currentPage.pageRef;
            size_t page = CGPDFPageGetPageNumber(pageRef);
            NSString *fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:self.pdfView.document.documentURL.path];
            if (page == 1) {
                [[MEGAStore shareInstance] deleteMediaDestinationWithFingerprint:fingerprint];
            } else {
                if (fingerprint && ![fingerprint isEqualToString:@""]) {
                    [[MEGAStore shareInstance] insertOrUpdateMediaDestinationWithFingerprint:fingerprint destination:[NSNumber numberWithLongLong:page] timescale:nil];
                }
            }
        }
    }

    [super viewWillDisappear:animated];
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
    
    if (self.node) {
        [self.imageView mnz_imageForNode:self.node];
    } else {
        [self.imageView mnz_setImageForExtension:[self.filesPathsArray objectAtIndex:self.nodeFileIndex].pathExtension];
    }
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorFromHexString:@"FCFCFC"];
    self.navigationController.navigationBar.tintColor = UIColor.mnz_redMain;
    self.navigationController.navigationBar.titleTextAttributes = @{NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]};
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
    } else if (self.node && self.nodeFilePath){
        return [NSURL fileURLWithPath:self.nodeFilePath];
    } else {
        self.title = [self.filesPathsArray objectAtIndex:self.nodeFileIndex].lastPathComponent;
        return [NSURL fileURLWithPath:[self.filesPathsArray objectAtIndex:self.nodeFileIndex]];
    }
}

- (void)loadQLController {
    self.activityIndicator.hidden = YES;
    self.progressView.hidden = YES;
    self.imageView.hidden = YES;
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
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:17.0f], NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:UIColor.mnz_redMain];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setTextColor:[UIColor whiteColor]];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setTintColor:[UIColor whiteColor]];
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
    actionController.actionSender = sender;
    actionController.displayMode = self.isLink ? DisplayModeFileLink : DisplayModeCloudDrive;
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        actionController.modalPresentationStyle = UIModalPresentationPopover;
        actionController.popoverPresentationController.delegate = actionController;
        actionController.popoverPresentationController.barButtonItem = sender;
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

- (void)presentMEGAQlPreviewController {
    MEGAQLPreviewController *previewController = [[MEGAQLPreviewController alloc] initWithFilePath:previewDocumentTransfer.path];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [UIApplication.mnz_presentingViewController presentViewController:previewController animated:YES completion:nil];
    }];
}

- (void)presentHtmlViewController {
    HtmlViewController *htmlVC = [HtmlViewController.alloc initWithFilePath:previewDocumentTransfer.path];
    MEGANavigationController *navigationController = [MEGANavigationController.alloc initWithRootViewController:htmlVC];
    [navigationController addLeftDismissButtonWithText:AMLocalizedString(@"ok", nil)];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
    }];
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
    float percentage = (transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue);
    [self.progressView setProgress:percentage];
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (error.type != MEGAErrorTypeApiOk) {
        return;
    }
    
    if (self.isViewLoaded && self.view.window) {
        if ([transfer.path.pathExtension isEqualToString:@"html"]) {
            [self presentHtmlViewController];
        } else {
            if (@available(iOS 11.0, *)) {
                if ([transfer.path.pathExtension isEqualToString:@"pdf"]) {
                    [self loadPdfKit:[NSURL fileURLWithPath:transfer.path]];
                } else {
                    [self presentMEGAQlPreviewController];
                }
            } else {
                [self presentMEGAQlPreviewController];
            }
        }
    }
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
            [node mnz_copyInViewController:self];
            break;
        case MegaNodeActionTypeMove:
            [node mnz_moveInViewController:self];
            break;
        case MegaNodeActionTypeImport:
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
                [self presentViewController:navigationController animated:YES completion:nil];
                
                BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
                browserVC.selectedNodesArray = @[node];
                browserVC.browserAction = BrowserActionImport;
            }
            break;
            
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
        [node navigateToParentAndPresent];
    }];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (IBAction)searchTapped:(id)sender {
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
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
        doubleTap.delegate = self;
        doubleTap.numberOfTapsRequired = 2;
        
        if (@available(iOS 13.0, *)) {
            UIGestureRecognizer *defaultDoubleTapGesture = [self.pdfView mnz_firstTapGestureWithNumberOfTaps:2];
            [defaultDoubleTapGesture requireGestureRecognizerToFail:doubleTap];
        }
        
        [self.pdfView addGestureRecognizer:doubleTap];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGesture:)];
        singleTap.numberOfTapsRequired = 1;
        singleTap.delegate = self;
        [singleTap requireGestureRecognizerToFail:doubleTap];
        [self.pdfView addGestureRecognizer:singleTap];
        
        self.pdfView.document = [[PDFDocument alloc] initWithURL:url];
        self.pdfView.autoScales = YES;
        self.pdfView.minScaleFactor = self.pdfView.scaleFactorForSizeToFit;
        
        NSString *fingerprint = [NSString stringWithFormat:@"%@", [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:self.pdfView.document.documentURL.path]];
        if (fingerprint && ![fingerprint isEqualToString:@""]) {
            NSNumber *destinationPage = [[MEGAStore shareInstance] fetchMediaDestinationWithFingerprint:fingerprint].destination;
            [self.pdfView goToPage:[self.pdfView.document pageAtIndex:destinationPage.unsignedIntegerValue - 1]];
        } else {
            [self.pdfView goToFirstPage:nil];
        }
    }
}

- (void)doubleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
    CGFloat newScale = self.pdfView.scaleFactor > 1.0f ? 1.0f : 2.0f;
    [UIView animateWithDuration:0.3 animations:^{
        if (newScale > 1.0f) {
            CGPoint tapPoint = [tapGestureRecognizer locationInView:self.pdfView];
            tapPoint = [self.pdfView convertPoint:tapPoint toPage:self.pdfView.currentPage];
            CGRect zoomRect = CGRectZero;
            zoomRect.size.width = self.pdfView.frame.size.width / newScale;
            zoomRect.size.height = self.pdfView.frame.size.height / newScale;
            zoomRect.origin.x = tapPoint.x - zoomRect.size.width / 2;
            zoomRect.origin.y = tapPoint.y - zoomRect.size.height / 2;
            [self.pdfView setScaleFactor:newScale];
            [self.pdfView goToRect:zoomRect onPage:self.pdfView.currentPage];
        } else {
            [self.pdfView setScaleFactor:self.pdfView.scaleFactorForSizeToFit];
        }
    } completion:nil];
}

- (void)singleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (self.navigationController.isToolbarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [self.navigationController setToolbarHidden:NO animated:YES];
    } else {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - CollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect pageRect = CGPDFPageGetBoxRect([self.pdfView.document pageAtIndex:indexPath.item].pageRef, kCGPDFMediaBox);
    float thumbnailWidth = (self.collectionView.frame.size.width - self.collectionView.layoutMargins.right - self.collectionView.layoutMargins.left - 50) / 3;
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
    if (@available(iOS 11.0, *)) {
        return self.pdfView.document.pageCount;
    } else {
        return 0;
    }
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
    if (!self.collectionView.hidden) {
        self.collectionView.hidden = YES;
        self.thumbnailBarButtonItem.image = [UIImage imageNamed:@"thumbnailsView"];
    }
    result.color = UIColor.yellowColor;
    [self.pdfView setCurrentSelection:result];
    [self.pdfView setScaleFactor:self.pdfView.scaleFactorForSizeToFit];
    [self.pdfView goToPage:result.pages.firstObject];
}

#pragma clang diagnostic pop

@end
