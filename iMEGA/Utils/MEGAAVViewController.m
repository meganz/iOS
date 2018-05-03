
#import "MEGAAVViewController.h"

#import "LTHPasscodeViewController.h"

#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.player play];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.player.currentItem];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    
    [self stopStreaming];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"presentPasscodeLater"] && [LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenOver:UIApplication.mnz_visibleViewController.view
                                                     withAnimation:YES
                                                        withLogout:NO
                                                    andLogoutTitle:nil];
    }
}

#pragma mark - Private

- (void)stopStreaming {
    if (self.node) {
        if (![self isFolderLink]) {
            [[MEGASdkManager sharedMEGASdk] httpServerStop];
        } else {
            [[MEGASdkManager sharedMEGASdkFolder] httpServerStop];
        }
    }
}

#pragma mark - Notifications

- (void)movieFinishedCallback:(NSNotification*)aNotification {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)applicationDidEnterBackground:(NSNotification*)aNotification {
    if (![NSStringFromClass([UIApplication sharedApplication].windows[0].class) isEqualToString:@"UIWindow"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"presentPasscodeLater"];
    }
}

#pragma mark - AVPlayerViewControllerDelegate

- (BOOL)playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart:(AVPlayerViewController *)playerViewController {
    return NO;
}

@end
