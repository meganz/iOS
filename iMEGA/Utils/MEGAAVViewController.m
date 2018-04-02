
#import "MEGAAVViewController.h"

#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "NSString+MNZCategory.h"

@interface MEGAAVViewController () <AVPlayerViewControllerDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, nonnull) NSURL *path;
@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, assign, getter=isFolderLink) BOOL folderLink;

@end

@implementation MEGAAVViewController

- (instancetype)initWithURL:(NSURL *)path {
    self = [super init];
    
    if (self) {
        _path       = path;
        _node       = nil;
        _folderLink = NO;
    }
    
    return self;
}

- (instancetype)initWithNode:(MEGANode *)node folderLink:(BOOL)folderLink {
    self = [super init];
    
    if (self) {
        _node       = node;
        _folderLink = folderLink;
        if (!folderLink) {
            _path = [[MEGASdkManager sharedMEGASdk] httpServerGetLocalLink:node];
        } else {
            _path = [[MEGASdkManager sharedMEGASdkFolder] httpServerGetLocalLink:node];
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.path) {
        return;
    }
    
    [self setTransitioningDelegate:self];
    
    self.player = [AVPlayer playerWithURL:self.path];
    self.delegate = self;
    
    if (self.node && !self.node.hasThumbnail && !self.isFolderLink && self.node.name.mnz_isVideoPathExtension) {
        [self.node mnz_generateThumbnailForVideoAtPath:self.path];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieFinishedCallback:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.player play];
}

#pragma mark - Notifications

- (void)movieFinishedCallback:(NSNotification*)aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.player.currentItem];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (self.node) {
        if (![self isFolderLink]) {
            [[MEGASdkManager sharedMEGASdk] httpServerStop];
        } else {
            [[MEGASdkManager sharedMEGASdkFolder] httpServerStop];
        }
    }
}

#pragma mark - AVPlayerViewControllerDelegate

- (BOOL)playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart:(AVPlayerViewController *)playerViewController {
    return NO;
}

@end
