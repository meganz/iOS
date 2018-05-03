
#import "MEGAAVViewController.h"

#import "LTHPasscodeViewController.h"

#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "MEGAStore.h"

@interface MEGAAVViewController () <AVPlayerViewControllerDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, nonnull) NSURL *fileUrl;
@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, assign, getter=isFolderLink) BOOL folderLink;
@property (nonatomic, assign, getter=isEndPlaying) BOOL endPlaying;

@end

@implementation MEGAAVViewController

- (instancetype)initWithURL:(NSURL *)fileUrl {
    self = [super init];
    
    if (self) {
        _fileUrl    = fileUrl;
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
        _fileUrl    = nil;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTransitioningDelegate:self];
    
    if (self.node && !self.node.hasThumbnail && !self.isFolderLink && self.node.name.mnz_isVideoPathExtension) {
        [self.node mnz_generateThumbnailForVideoAtPath:self.fileUrl];
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
    
    NSString *fingerprint = [self fileFingerprint];

    if (fingerprint && ![fingerprint isEqualToString:@""]) {
        MOMediaDestination *mediaDestination = [[MEGAStore shareInstance] fetchMediaDestinationWithFingerprint:fingerprint];
        if (mediaDestination) {
            UIAlertController *resumeOrRestartAlert = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"continuePlaying", @"Title to alert user the posibility of continue playing video or start again") message:AMLocalizedString(@"continueOrRestartVideo", @"Message to alert user the posibility of continue playing video or start again") preferredStyle:UIAlertControllerStyleAlert];
            [resumeOrRestartAlert addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"continue", @"'Next' button in a dialog") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self playWithDestination:mediaDestination];
            }]];
            [resumeOrRestartAlert addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"restart", @"A label for the Restart button to relaunch MEGAsync.") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self playWithDestination:nil];
            }]];
            [self presentViewController:resumeOrRestartAlert animated:YES completion:nil];
        } else {
            [self playWithDestination:nil];
        }
    } else {
        [self playWithDestination:nil];
    }
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

- (void)viewWillDisappear:(BOOL)animated {
    NSString *fingerprint = [self fileFingerprint];

    if (fingerprint && ![fingerprint isEqualToString:@""]) {
        if (self.isEndPlaying) {
            [[MEGAStore shareInstance] deleteMediaDestinationWithFingerprint:fingerprint];
        } else {
            [[MEGAStore shareInstance] insertOrUpdateMediaDestinationWithFingerprint:fingerprint destination:[NSNumber numberWithLongLong:self.player.currentTime.value] timescale:[NSNumber numberWithInt:self.player.currentTime.timescale]];
        }
    }
    
    [super viewWillDisappear:animated];
}

#pragma mark - Private

- (void)playWithDestination:(MOMediaDestination *)mediaDestination {
    if (self.node) {
        if (self.folderLink) {
            self.fileUrl = [[MEGASdkManager sharedMEGASdkFolder] httpServerGetLocalLink:self.node];
        } else {
            self.fileUrl = [[MEGASdkManager sharedMEGASdk] httpServerGetLocalLink:self.node];
        }
    }
    
    if (!self.fileUrl) {
        return;
    }
    
    self.player = [AVPlayer playerWithURL:self.fileUrl];
    self.delegate = self;
    
    if (mediaDestination) {
        [self.player seekToTime:CMTimeMake(mediaDestination.destination.longLongValue, mediaDestination.timescale.intValue)];
    }
    
    [self.player play];
}


- (void)stopStreaming {
    if (self.node) {
        if (self.isFolderLink) {
            [[MEGASdkManager sharedMEGASdkFolder] httpServerStop];
        } else {
            [[MEGASdkManager sharedMEGASdk] httpServerStop];
        }
    }
}

- (NSString *)fileFingerprint {
    NSString *fingerprint = [NSString new];

    if (self.node) {
        if (self.folderLink) {
            fingerprint = [[MEGASdkManager sharedMEGASdkFolder] fingerprintForNode:self.node];
        } else {
            fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForNode:self.node];
        }
    } else {
        fingerprint = [NSString stringWithFormat:@"%@", [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:self.fileUrl.path]];
    }
    
    return fingerprint;
}

#pragma mark - Notifications

- (void)movieFinishedCallback:(NSNotification*)aNotification {
    self.endPlaying = YES;
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
