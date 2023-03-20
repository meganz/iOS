
#import "PreviewDocumentViewController.h"

#import <PDFKit/PDFKit.h>

#import "SVProgressHUD.h"

#import "Helper.h"
#import "CopyrightWarningViewController.h"
#import "MEGAQLPreviewController.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "BrowserViewController.h"
#import "CloudDriveViewController.h"
#import "MainTabBarController.h"
#import "SearchInPdfViewController.h"
#import "SendToViewController.h"
#import "MEGALinkManager.h"

#import "MEGANode+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "UIView+MNZCategory.h"
@import PureLayout;

@interface PreviewDocumentViewController () <QLPreviewControllerDataSource, QLPreviewControllerDelegate, MEGATransferDelegate, UICollectionViewDelegate, UICollectionViewDataSource, NodeActionViewControllerDelegate, NodeInfoViewControllerDelegate, SearchInPdfViewControllerProtocol, UIGestureRecognizerDelegate, PDFViewDelegate> {
    MEGATransfer *previewDocumentTransfer;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet PDFView *pdfView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *thumbnailBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *outlineBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *exportFileBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *importBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) QLPreviewController *previewController;
@property (nonatomic) NSString *nodeFilePath;
@property (nonatomic, nullable) NSString * textContent;
@property (nonatomic) NSCache<NSNumber *, UIImage *> *thumbnailCache;
@property (nonatomic) BOOL thumbnailsPopulated;
@property (nonatomic) PDFSelection *searchedItem;

@property (nonatomic) SendLinkToChatsDelegate *sendLinkDelegate;

@property (nonatomic) UIButton *openZipButton;
@property (nonatomic) PDFOutlineView *outlineView;

@end

@implementation PreviewDocumentViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.node == nil && self.nodeHandle != MEGAInvalidHandle) {
        self.node = [MEGASdkManager.sharedMEGASdk nodeForHandle:self.nodeHandle];
    }
    
    self.thumbnailCache = [[NSCache alloc] init];
    
    [self configureNavigation];
    [self configureDocumentOutline];
    [self updateAppearance];
    
    self.closeBarButtonItem.title = NSLocalizedString(@"close", @"A button label.");
    
    self.moreBarButtonItem.accessibilityLabel = NSLocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
    
    if (self.showUnknownEncodeHud) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"general.textEditor.hud.unknownEncode", @"Hud info message when read unknown encode file.")];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.filePath) {
        [self loadPreview];
    } else {
        NSError * error = nil;
        NSString *nodeFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.node base64Handle]];
        self.nodeFilePath = [nodeFolderPath stringByAppendingPathComponent:self.node.name];
        
        if ([[NSFileManager defaultManager] createDirectoryAtPath:nodeFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            [MEGASdkManager.sharedMEGASdk startDownloadNode:self.node localPath:self.nodeFilePath fileName:nil appData:nil startFirst:NO cancelToken:nil delegate:self];
        } else {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (previewDocumentTransfer) {
        [MEGASdkManager.sharedMEGASdk cancelTransfer:previewDocumentTransfer];
    }
    
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

    [super viewWillDisappear:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.previewController.view.frame = self.view.bounds;
        [self.pdfView setScaleFactor:self.pdfView.scaleFactorForSizeToFit];
    } completion:nil];
    
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
        [AppearanceManager forceToolbarUpdate:self.navigationController.toolbar traitCollection:self.traitCollection];
        
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)configureNavigation {
    [self setTitle:self.node.name];
    
    self.navigationItem.rightBarButtonItem = nil;
    
    if (self.node) {
        self.navigationItem.rightBarButtonItem = self.moreBarButtonItem;
        [self.imageView setImage:[NodeAssetsManager.shared iconFor:self.node]];
    } else {
        [self.imageView setImage:[NodeAssetsManager.shared imageFor:self.filePath.pathExtension]];
    }
    
    [self.navigationController.toolbar setBackgroundColor:[UIColor mnz_mainBarsForTraitCollection:self.traitCollection]];
}

- (void)configureDocumentOutline {
    PDFOutlineView *outlineView = [[PDFOutlineView alloc] initWithOutline:@[]];
    self.outlineView = outlineView;
    [self.view addSubview:outlineView];
    outlineView.translatesAutoresizingMaskIntoConstraints = NO;
    [outlineView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = YES;
    [outlineView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    [outlineView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor].active = YES;
    [outlineView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor].active = YES;
    [self hideOutlineView:YES];
    outlineView.selectOutlineItemHandler = ^(PDFOutlineItem * _Nonnull outlineItem) {
        [self.pdfView goToPage:[self.pdfView.document pageAtIndex:(outlineItem.pageNumber - 1)]];
        [self hideOutlineView:YES];
    };
}

- (void)hideOutlineView:(BOOL)hide {
    self.outlineView.hidden = hide;
    if (hide) {
        self.outlineBarButtonItem.image = [[UIImage systemImageNamed:@"line.3.horizontal.circle"] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]];
    } else {
        self.outlineBarButtonItem.image = [[UIImage systemImageNamed:@"line.3.horizontal.circle.fill"] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]];
    }
}

- (void)loadPreview {
    NSURL *url = [self documentUrl];
    self.textContent = [[NSString alloc] initWithContentsOfFile:url.path usedEncoding:nil error:nil];
    if (self.textContent != nil
        && [url.path mnz_isEditableTextFilePathExtension]) {
        [self loadTextView];
    } else if ([url.pathExtension isEqualToString:@"pdf"]) {
        [self loadPdfKit:url];
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
        self.title = self.filePath.lastPathComponent;
        return [NSURL fileURLWithPath:self.filePath];
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
    
    UIBarButtonItem *flexibleItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSMutableArray *toolbarItems = NSMutableArray.new;
    [toolbarItems addObjectsFromArray:@[self.downloadBarButtonItem, flexibleItem]];
    if ([MEGASdkManager.sharedMEGASdk accessLevelForNode:self.node] == MEGAShareTypeAccessOwner) {
        [toolbarItems addObject:self.exportFileBarButtonItem];
    } else {
        [toolbarItems addObject:self.importBarButtonItem];
    }
    self.toolbarItems = toolbarItems.copy;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    [self.view addSubview:self.previewController.view];
    
    if ([self.filePath.pathExtension.lowercaseString isEqual: @"zip"] || [self.nodeFilePath.pathExtension.lowercaseString isEqual: @"zip"]) {
        [self createOpenZipButton];
    }
}

- (void)loadTextView {
    UITextView *textView = [[UITextView alloc] init];
    textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    textView.adjustsFontForContentSizeCategory = YES;
    [self.view addSubview:textView];
    [textView autoPinEdgesToSuperviewSafeArea];
    [textView setEditable:NO];
    textView.text = self.textContent;
}

- (void)import {
    if (self.node == nil) {
        return;
    }
    
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.selectedNodesArray = @[self.node];
        browserVC.browserAction = BrowserActionImport;
    }
}

- (void)sendToChat {
    if (self.isLink && self.fileLink) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"SendToNavigationControllerID"];
        SendToViewController *sendToViewController = navigationController.viewControllers.firstObject;
        sendToViewController.sendMode = SendModeFileAndFolderLink;
        self.sendLinkDelegate = [SendLinkToChatsDelegate.alloc initWithLink:self.fileLink navigationController:self.navigationController];
        sendToViewController.sendToViewControllerDelegate = self.sendLinkDelegate;
        [self presentViewController:navigationController animated:YES completion:nil];
    } else {
        [self.node mnz_sendToChatInViewController:self];
    }
}

- (void)download {
    if (self.isLink && self.fileLink) {
        [self downloadFileLink];
    } else if (self.chatId && self.messageId) {
        [CancellableTransferRouterOCWrapper.alloc.init downloadChatNodes:@[self.node] messageId:self.messageId chatId:self.chatId presenter:self];
    } else if (self.node != nil) {
        [CancellableTransferRouterOCWrapper.alloc.init downloadNodes:@[self.node] presenter:self isFolderLink:self.isLink];
    }
}

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    
    [self.openZipButton mnz_setupBasic:self.traitCollection];
}

- (void)createOpenZipButton {
    UIButton *openZipButton = [UIButton newAutoLayoutView];
    [openZipButton setTitle:NSLocalizedString(@"openButton", @"Button title to trigger the action of opening the file without downloading or opening it.") forState:UIControlStateNormal];
    [openZipButton mnz_setupBasic:self.traitCollection];
    [self.view addSubview:openZipButton];
    [openZipButton autoSetDimension:ALDimensionWidth toSize:300];
    [openZipButton autoSetDimension:ALDimensionHeight toSize:60];
    [openZipButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [openZipButton autoPinEdgeToSuperviewSafeArea:ALEdgeBottom withInset:UIDevice.currentDevice.iPad ? 32 : 16];
    [openZipButton addTarget:self action:@selector(openZipInQLViewController) forControlEvents:UIControlEventTouchUpInside];
    
    self.openZipButton = openZipButton;
}

- (void)presentActivityVC:(NSArray *)activityItems barButtonItem:(id)sender {
    UIActivityViewController *activityVC = [UIActivityViewController.alloc initWithActivityItems:activityItems applicationActivities:nil];
    activityVC.popoverPresentationController.barButtonItem = sender;
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)exportFileAction:(id)sender {
    if (self.node) {
        [self exportFileFrom:self.node sender:sender];
    } else {
        if (self.filePath) {
            [self presentActivityVC:@[[NSURL fileURLWithPath:self.filePath]] barButtonItem:sender];
        }
    }
}

- (IBAction)doneTapped:(id)sender {
    [TransfersWidgetViewController.sharedTransferViewController resetToKeyWindow];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)thumbnailTapped:(id)sender {
    if (!self.outlineView.hidden) {
        [self hideOutlineView:YES];
        return;
    }
    if (self.collectionView.hidden) {
        if (!self.thumbnailsPopulated) {
            [self.collectionView reloadData];
            self.thumbnailsPopulated = YES;
        }
        self.collectionView.hidden = NO;
        self.thumbnailBarButtonItem.image = [UIImage imageNamed:@"pageView"];
    } else {
        self.collectionView.hidden = YES;
        self.thumbnailBarButtonItem.image = [UIImage imageNamed:@"thumbnailsThin"];
    }
    
}

- (IBAction)outlineTapped:(id)sender {
    [self hideOutlineView:!self.outlineView.hidden];
}

- (IBAction)actionsTapped:(UIBarButtonItem *)sender {
    if ([MEGASdkManager.sharedMEGASdk accessLevelForNode:self.node] != MEGAShareTypeAccessUnknown) {
        self.node = [MEGASdkManager.sharedMEGASdk nodeForHandle:self.node.handle];
    }
    
    DisplayMode displayMode = self.node.mnz_isInRubbishBin ? DisplayModeRubbishBin : self.collectionView.hidden ? DisplayModePreviewPdfPage :  DisplayModePreviewDocument;
    BOOL isBackupNode = [[[MyBackupsOCWrapper alloc] init] isBackupNode:self.node];
    NodeActionViewController *nodeActions = [NodeActionViewController.alloc
                                             initWithNode:self.node
                                             delegate:self
                                             isLink:self.isLink
                                             displayMode:displayMode
                                             isInVersionsView:[self isPreviewingVersion]
                                             isBackupNode:isBackupNode
                                             sender:sender];
    [self presentViewController:nodeActions animated:YES completion:nil];
}

- (IBAction)importAction:(id)sender {
    [self import];
}

- (IBAction)downloadAction:(id)sender {
    [self download];
}

- (void)openZipInQLViewController {
    NSString *filePath = self.nodeFilePath ? self.nodeFilePath : self.filePath;
    MEGAQLPreviewController *previewController = [MEGAQLPreviewController.alloc initWithFilePath:filePath];
    [self dismissViewControllerAnimated:YES completion:^{
        [UIApplication.mnz_presentingViewController presentViewController:previewController animated:YES completion:nil];
    }];
}

- (BOOL)isPreviewingVersion {
    if ([[self.navigationController presentingViewController] isKindOfClass:[MEGANavigationController class]]) {
        NSArray<UIViewController *>*viewcontrollers = [[self.navigationController presentingViewController] childViewControllers];
        if ([viewcontrollers.lastObject isKindOfClass:[NodeVersionsViewController class]]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    if (self.filePath) {
        return [NSURL fileURLWithPath:self.filePath];
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
        [self loadPreview];
    }
}

#pragma mark - NodeActionViewControllerDelegate

- (void)nodeAction:(NodeActionViewController *)nodeAction didSelect:(MegaNodeActionType)action for:(MEGANode *)node from:(id)sender {
    switch (action) {
        case MegaNodeActionTypeExportFile:
            [self exportFileAction:sender];
            break;
            
        case MegaNodeActionTypeDownload:
            [self download];
            break;
            
        case MegaNodeActionTypeInfo: {
            MEGANavigationController *nodeInfoNavigation = [NodeInfoViewController instantiateWithViewModel:[self createNodeInfoViewModelWithNode:node]
                                                                                                   delegate:self];
            [self presentViewController:nodeInfoNavigation animated:YES completion:nil];
            break;
        }
            
        case MegaNodeActionTypeFavourite: {
            MEGAGenericRequestDelegate *delegate = [MEGAGenericRequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
                if (error.type == MEGAErrorTypeApiOk) {
                    if (request.numDetails == 1) {
                        [[QuickAccessWidgetManager.alloc init] insertFavouriteItemFor:node];
                    } else {
                        [[QuickAccessWidgetManager.alloc init] deleteFavouriteItemFor:node];
                    }
                }
            }];
            [MEGASdkManager.sharedMEGASdk setNodeFavourite:node favourite:!node.isFavourite delegate:delegate];
            break;
        }
            
        case MegaNodeActionTypeLabel:
            [node mnz_labelActionSheetInViewController:self];
            break;
        
        case MegaNodeActionTypeCopy:
            [node mnz_copyInViewController:self];
            break;
            
        case MegaNodeActionTypeMove:
            [node mnz_moveInViewController:self];
            break;
            
        case MegaNodeActionTypeImport:
            [self import];
            break;
            
        case MegaNodeActionTypeRename: {
            [node mnz_renameNodeInViewController:self completion:^(MEGARequest *request) {
                [self setTitle:request.name];
            }];
            break;
        }
            
        case MegaNodeActionTypeMoveToRubbishBin:
            [node mnz_askToMoveToTheRubbishBinInViewController:self];
            break;
            
        case MegaNodeActionTypeManageLink:
        case MegaNodeActionTypeShareLink: {
            if (self.isLink && self.fileLink) {
                [self presentActivityVC:@[self.fileLink] barButtonItem:self.moreBarButtonItem];
            } else if (MEGAReachabilityManager.isReachableHUDIfNot) {
                [CopyrightWarningViewController presentGetLinkViewControllerForNodes:@[node] inViewController:UIApplication.mnz_presentingViewController];
            }
            break;
        }
            
        case MegaNodeActionTypeRemoveLink: {
            [node mnz_removeLink];
            break;
        }
            
        case MegaNodeActionTypeSendToChat:
            [self sendToChat];
            break;
            
        case MegaNodeActionTypePdfPageView:
        case MegaNodeActionTypePdfThumbnailView:
            [self thumbnailTapped:nil];
            break;
            
        case MegaNodeActionTypeSearch:
            [self searchTapped:nil];
            break;
        
        case MegaNodeActionTypeRestore:
            [self dismissViewControllerAnimated:YES completion:nil];
            [node mnz_restore];
            break;
            
        case MegaNodeActionTypeRemove:
            [node mnz_removeInViewController:self completion:nil];

        case MegaNodeActionTypeViewVersions:
            [node mnz_showNodeVersionsInViewController:self];
            
        default:
            break;
    }
}

#pragma mark - NodeInfoViewControllerDelegate

- (void)nodeInfoViewController:(NodeInfoViewController *)nodeInfoViewController presentParentNode:(MEGANode *)node {
    [self dismissViewControllerAnimated:YES completion:^{
        [node navigateToParentAndPresent];
    }];
}

- (IBAction)searchTapped:(id)sender {
    UINavigationController *searchInPdfNavigation = [[UIStoryboard storyboardWithName:@"DocumentPreviewer" bundle:nil] instantiateViewControllerWithIdentifier:@"SearchInPdfNavigationID"];
    SearchInPdfViewController *searchInPdfVC = searchInPdfNavigation.viewControllers.firstObject;
    searchInPdfVC.pdfDocument = self.pdfView.document;
    searchInPdfVC.delegate = self;
    [self presentViewController:searchInPdfNavigation animated:YES completion:nil];
}

- (void)loadPdfKit:(NSURL *)url {
    if (!self.pdfView.document) {
        self.pdfView.hidden = NO;
        self.pdfView.delegate = self;
        self.activityIndicator.hidden = YES;
        self.progressView.hidden = YES;
        self.imageView.hidden = YES;
        
        self.pdfView.document = [[PDFDocument alloc] initWithURL:url];
        self.pdfView.autoScales = YES;
        self.pdfView.minScaleFactor = self.pdfView.scaleFactorForSizeToFit;
        self.outlineView.outline = [PDFOutlineItem getOutline:self.pdfView.document];
        [self.outlineView reload];
        
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        if (self.node) {
            if (self.node.mnz_isInRubbishBin) {
                [self setToolbarItems:@[self.thumbnailBarButtonItem, flexibleItem, self.searchBarButtonItem] animated:YES];
            } else {
                if (self.pdfView.document.outlineRoot) {
                    [self setToolbarItems:@[self.thumbnailBarButtonItem, flexibleItem, self.outlineBarButtonItem, flexibleItem, self.searchBarButtonItem, flexibleItem, [MEGASdkManager.sharedMEGASdk accessLevelForNode:self.node] == MEGAShareTypeAccessOwner ? self.exportFileBarButtonItem : self.importBarButtonItem] animated:YES];
                } else {
                    [self setToolbarItems:@[self.thumbnailBarButtonItem, flexibleItem, self.searchBarButtonItem, flexibleItem, [MEGASdkManager.sharedMEGASdk accessLevelForNode:self.node] == MEGAShareTypeAccessOwner ? self.exportFileBarButtonItem : self.importBarButtonItem] animated:YES];
                }
            }
        } else {
            [self setToolbarItems:@[self.thumbnailBarButtonItem, flexibleItem, self.searchBarButtonItem, flexibleItem, self.exportFileBarButtonItem] animated:YES];
        }
        [self.navigationController setToolbarHidden:NO animated:YES];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
        doubleTap.delegate = self;
        doubleTap.numberOfTapsRequired = 2;
        
        UIGestureRecognizer *defaultDoubleTapGesture = [self.pdfView mnz_firstTapGestureWithNumberOfTaps:2];
        [defaultDoubleTapGesture requireGestureRecognizerToFail:doubleTap];
        
        [self.pdfView addGestureRecognizer:doubleTap];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGesture:)];
        singleTap.numberOfTapsRequired = 1;
        singleTap.delegate = self;
        [singleTap requireGestureRecognizerToFail:doubleTap];
        [self.pdfView addGestureRecognizer:singleTap];
        
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
    if (self.pdfView.currentSelection) {
        [self.pdfView clearSelection];
    } else {
        if (self.navigationController.isToolbarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            [self.navigationController setToolbarHidden:NO animated:YES];
        } else {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            [self.navigationController setToolbarHidden:YES animated:YES];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
        [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}


#pragma mark - PDFViewDelegate

- (void)PDFViewWillClickOnLink:(PDFView *)sender withURL:(NSURL *)url {
    
    MEGALinkManager.linkURL = url;
    [MEGALinkManager processLinkURL:url];
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
    self.thumbnailBarButtonItem.image = [UIImage imageNamed:@"thumbnailsThin"];
    self.collectionView.hidden = YES;
}

#pragma mark - CollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.pdfView.document.pageCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"ThumbnailPageID" forIndexPath:indexPath];
    UILabel *pageLabel = [cell viewWithTag:1];
    pageLabel.text = [NSString stringWithFormat:@"%ld", (long)indexPath.item + 1];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    UIImageView *imageView = [cell viewWithTag:100];
    NSNumber *cachedImageKey = @(indexPath.item);
    UIImage *cachedImage = [self.thumbnailCache objectForKey:cachedImageKey];
    if (cachedImage) {
        imageView.image = cachedImage;
    } else {
        PDFPage *page = [self.pdfView.document pageAtIndex:indexPath.item];
        if (page) {
            @try {
                UIImage *thumbnail = [page thumbnailOfSize:CGSizeMake(100, 100) forBox:kPDFDisplayBoxMediaBox];
                if (thumbnail) {
                    imageView.image = thumbnail;
                    [self.thumbnailCache setObject:thumbnail forKey:cachedImageKey];
                }
            } @catch (NSException *exception) {
                imageView.image = [UIImage imageNamed:@"pdf"];
                MEGALogError(@"Exception during thumbnail caching: %@", exception);
            }
        }
    }
}

#pragma mark - SearchInPdfViewControllerProtocol

- (void)didSelectSearchResult:(PDFSelection *)result {
    if (!self.collectionView.hidden) {
        self.collectionView.hidden = YES;
        self.thumbnailBarButtonItem.image = [UIImage imageNamed:@"thumbnailsThin"];
    }
    result.color = UIColor.systemYellowColor;
    [self.pdfView setCurrentSelection:result];
    [self.pdfView setScaleFactor:self.pdfView.scaleFactorForSizeToFit];
    [self.pdfView goToPage:result.pages.firstObject];
}

@end
