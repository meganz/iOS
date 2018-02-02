
#import "MEGAPhotoBrowserViewController.h"

#import "Helper.h"
#import "MEGAGetPreviewRequestDelegate.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAStartDownloadTransferDelegate.h"

#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"

@interface MEGAPhotoBrowserViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic) NSMutableArray<MEGANode *> *mediaNodes;

@end

@implementation MEGAPhotoBrowserViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mediaNodes = [[NSMutableArray<MEGANode *> alloc] init];
    
    for (NSUInteger i=0; i<self.nodeList.size.unsignedIntegerValue; i++) {
        MEGANode *currentNode = [self.nodeList nodeAtIndex:i];
        if (currentNode.name.mnz_isImagePathExtension || currentNode.name.mnz_isVideoPathExtension) {
            [self.mediaNodes addObject:currentNode];
        }
    }
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
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.scrollView.frame.size.width * i++, 0.0f, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
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
        }
    }
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

@end
