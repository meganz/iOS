#import "MEGAActivityItemProvider.h"

#import <LinkPresentation/LinkPresentation.h>

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAStartDownloadTransferDelegate.h"
#import "MEGAExportRequestDelegate.h"
#import "SVProgressHUD.h"
#import "UIApplication+MNZCategory.h"
#import "YYCategories.h"
#import <PureLayout/PureLayout.h>

#import "Helper.h"
#import "UIImageView+MNZCategory.h"

@interface MEGAActivityItemProvider () <UIActivityItemSource, MEGARequestDelegate> {
}

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) MEGATransfer *transfer;
@property (strong, nonatomic) NSString *link;
@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) MEGASdk *api;

@end

@implementation MEGAActivityItemProvider

- (instancetype)initWithPlaceholderString:(NSString *)placeholder node:(MEGANode *)node api:(MEGASdk *)api {
    self = [super initWithPlaceholderItem:placeholder];
    if (self) {
        _node = node;
        _link = @"";
        _api = api;
    }
    return self;
}

- (id)item {
    @weakify(self)
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSString *activityType = [self activityType];
    BOOL activityValue = !([activityType isEqualToString:MEGAUIActivityTypeOpenIn] || [activityType isEqualToString:MEGAUIActivityTypeGetLink] || [activityType isEqualToString:MEGAUIActivityTypeRemoveLink] || [activityType isEqualToString:MEGAUIActivityTypeShareFolder] || [activityType isEqualToString:MEGAUIActivityTypeSaveToCameraRoll] || [activityType isEqualToString:MEGAUIActivityTypeRemoveSharing] || [activityType isEqualToString:MEGAUIActivityTypeSendToChat]);
    if (activityValue) {
        if (self.node.isFile && [self.node mnz_downloadNodeTopPriority]) {
            MEGAStartDownloadTransferDelegate *delegate = [[MEGAStartDownloadTransferDelegate alloc] initWithStart:nil progress:^(MEGATransfer *transfer) {
                @strongify(self)
                
                if (transfer.nodeHandle == self.node.handle) {
                    
                    self.transfer = transfer;
                    float percentage = (transfer.transferredBytes.floatValue/transfer.totalBytes.floatValue);

                    self.progressView.progress = percentage;
                    
                }
            } completion:^(MEGATransfer *transfer) {
                @strongify(self)
                if (transfer.nodeHandle == self.node.handle) {
                    self.link = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:transfer.path]].absoluteString;
                    [self.alertController dismissViewControllerAnimated:YES completion:nil];
                    dispatch_semaphore_signal(semaphore);
                }
            } onError:^(MEGATransfer *transfer, MEGAError *error) {
                @strongify(self)
                
                [self cancel];
                
                [self.alertController dismissViewControllerAnimated:YES completion:nil];
                dispatch_semaphore_signal(semaphore);
            }];
            
            [self.api addMEGATransferDelegate:delegate];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![UIApplication.mnz_presentingViewController isKindOfClass:UIAlertController.class] && UIApplication.mnz_presentingViewController != self.alertController && !self.alertController.presentingViewController) {
                    [UIApplication.mnz_presentingViewController presentViewController:self.alertController animated:YES completion:nil];
                }
                
            });
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            [self.api removeMEGATransferDelegate:delegate];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.alertController dismissViewControllerAnimated:YES completion:nil];
            });
        } else {
            if (!self.node.isExported) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if (MEGAReachabilityManager.isReachableHUDIfNot) {
                        MEGAExportRequestDelegate *requestDelegate = [[MEGAExportRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                            @strongify(self)
                            if ([request access]) {
                                self.link = [request link];
                                [SVProgressHUD dismiss];
                                dispatch_semaphore_signal(semaphore);
                            }
                        } multipleLinks:false];
                        
                        [self.api exportNode:self.node delegate:requestDelegate];
                    }
                });
                double delayInSeconds = 10.0;
                dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_semaphore_wait(semaphore, waitTime);
            } else {
                self.link = self.node.publicLink;
            }
        }
    }
    
    return _link;
}

#pragma mark- private

- (UIAlertController *)alertController {
    if (!_alertController) {
        NSString *title = [[NSString stringWithFormat:NSLocalizedString(@"Downloading %@", @"Label for the status of a transfer when is being Downloading - (String as short as possible."), self.node.name] stringByAppendingString:@"\n"];
        _alertController = [UIAlertController alertControllerWithTitle:title message:@"\n" preferredStyle:UIAlertControllerStyleAlert];
        @weakify(self)
        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            MEGALogDebug(@"[PA] User cancelled the export session");
            @strongify(self)
            [self cancel];
            [self.api cancelTransfer:self.transfer];
        }]];
        
        self.progressView = [[UIProgressView alloc] init];
        self.progressView.progress = 0.0;
        self.progressView.tintColor = [UIColor mnz_turquoiseForTraitCollection:UIScreen.mainScreen.traitCollection];
        [_alertController.view addSubview:self.progressView];
        [self.progressView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:80];
        [self.progressView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
        [self.progressView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
        [self.progressView autoSetDimension:ALDimensionHeight toSize:2];
        
    }
    return _alertController;
 
}

#pragma mark - UIActivityItemSource

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    if ((self.isCancelled || self.node.isFolder) && self.node.isExported) {
        self.link = self.node.publicLink;
        return self.link;
    }

    if ([activityType isEqualToString:MEGAUIActivityTypeOpenIn] || [activityType isEqualToString:MEGAUIActivityTypeGetLink] || [activityType isEqualToString:MEGAUIActivityTypeRemoveLink] || [activityType isEqualToString:MEGAUIActivityTypeShareFolder] || [activityType isEqualToString:MEGAUIActivityTypeSaveToCameraRoll] || [activityType isEqualToString:MEGAUIActivityTypeRemoveSharing]) {

        return nil;
    }

    return [NSURL URLWithString:self.link];
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size {
    return [UIImage imageNamed:@"AppIcon"];
}

- (LPLinkMetadata *)activityViewControllerLinkMetadata:(UIActivityViewController *)activityViewController {
    LPLinkMetadata *metadata = LPLinkMetadata.new;
    metadata.title = self.node.name;

    NSString *subtitleString = @"";
    if (self.node.isFile) {
        subtitleString = [Helper sizeAndModicationDateForNode:self.node api:self.api];
    } else if (self.node.isFolder) {
        subtitleString = [Helper filesAndFoldersInFolderNode:self.node api:self.api];
    }
    metadata.originalURL = [NSURL.alloc initFileURLWithPath:subtitleString];

    if (self.node.hasThumbnail) {
        NSString *thumbnailFilePath = [Helper pathForNode:self.node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
        NSString *previewFilePath = [Helper pathForNode:self.node inSharedSandboxCacheDirectory:@"previewsV3"];
        UIImage *icon;
        if ([NSFileManager.defaultManager fileExistsAtPath:thumbnailFilePath]) {
            icon = [UIImage imageWithContentsOfFile:thumbnailFilePath];
        } else if ([NSFileManager.defaultManager fileExistsAtPath:previewFilePath]) {
            icon = [UIImage imageWithContentsOfFile:previewFilePath];
        }
        NSItemProvider *iconItemProvider = [NSItemProvider.new initWithObject:icon];
        metadata.iconProvider = iconItemProvider;
    } else {
        UIImageView *imageView = UIImageView.new;
        [imageView mnz_imageForNode:self.node];
        NSItemProvider *iconItemProvider = [NSItemProvider.new initWithObject:imageView.image];
        metadata.iconProvider = iconItemProvider;
    }

    return metadata;
}

- (void)cancel {
    [super cancel];
    [self.api cancelTransfer:self.transfer];
}

- (void)dealloc {
    [self.api cancelTransfer:self.transfer];
}

@end
