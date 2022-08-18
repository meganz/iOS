
#import "MEGAAVViewController.h"

#import "LTHPasscodeViewController.h"

#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"

static const NSUInteger MIN_SECOND = 10; // Save only where the users were playing the file, if the streaming second is greater than this value.

@interface MEGAAVViewController () <AVPlayerViewControllerDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, nonnull) NSURL *fileUrl;
@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, assign, getter=isFolderLink) BOOL folderLink;
@property (nonatomic, assign, getter=isEndPlaying) BOOL endPlaying;
@property (nonatomic, strong) MEGASdk *apiForStreaming;

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

- (instancetype)initWithNode:(MEGANode *)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk *)apiForStreaming {
    self = [super init];
    
    if (self) {
        _apiForStreaming = apiForStreaming;
        _node            = folderLink ? [[MEGASdkManager sharedMEGASdkFolder] authorizeNode:node] : node;
        _folderLink      = folderLink;
        _fileUrl         = [[MEGASdkManager sharedMEGASdk] httpServerIsLocalOnly] ? [apiForStreaming httpServerGetLocalLink:_node] : [[apiForStreaming httpServerGetLocalLink:_node] mnz_updatedURLWithCurrentAddress];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkNetworkChanges)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkNetworkChanges)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared audioInterruptionDidStart];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSString *fingerprint = [self fileFingerprint];

    if (fingerprint && ![fingerprint isEqualToString:@""]) {
        MOMediaDestination *mediaDestination = [[MEGAStore shareInstance] fetchMediaDestinationWithFingerprint:fingerprint];
        if (mediaDestination.destination.longLongValue > 0 && mediaDestination.timescale.intValue > 0) {
            if ([self fileName].mnz_isVideoPathExtension) {
                NSString *infoVideoDestination = NSLocalizedString(@"continueOrRestartVideoMessage", @"Message to show the user info (name and time) about the resume of the video");
                infoVideoDestination = [infoVideoDestination stringByReplacingOccurrencesOfString:@"%1$s" withString:[self fileName]];
                infoVideoDestination = [infoVideoDestination stringByReplacingOccurrencesOfString:@"%2$s" withString:[self timeForMediaDestination:mediaDestination]];
                UIAlertController *resumeOrRestartAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"resumePlayback", @"Title to alert user the possibility of resume playing the video or start from the beginning") message:infoVideoDestination preferredStyle:UIAlertControllerStyleAlert];
                [resumeOrRestartAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"resume", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self seekToDestination:mediaDestination play:YES];
                }]];
                [resumeOrRestartAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"restart", @"A label for the Restart button to relaunch MEGAsync.") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self seekToDestination:nil play:YES];
                }]];
                [self presentViewController:resumeOrRestartAlert animated:YES completion:nil];
            } else {
                [self seekToDestination:mediaDestination play:NO];
            }
        } else {
            [self seekToDestination:nil play:YES];
        }
    } else {
        [self seekToDestination:nil play:YES];
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kReachabilityChangedNotification
                                                  object:nil];
    
    [self stopStreaming];
        
    if (![AudioPlayerManager.shared isPlayerAlive]) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionMixWithOthers error:nil];
        [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVoiceChat error:nil];
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"presentPasscodeLater"] && [LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenOver:UIApplication.mnz_presentingViewController.view
                                                     withAnimation:YES
                                                        withLogout:YES
                                                    andLogoutTitle:NSLocalizedString(@"logoutLabel", nil)];
    }
    
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared audioInterruptionDidEndNeedToResume:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    CMTime mediaTime = CMTimeMake(self.player.currentTime.value, self.player.currentTime.timescale);
    Float64 second = CMTimeGetSeconds(mediaTime);
    
    NSString *fingerprint = [self fileFingerprint];
    
    if (fingerprint && ![fingerprint isEqualToString:@""]) {
        if (self.isEndPlaying || second <= MIN_SECOND) {
            [[MEGAStore shareInstance] deleteMediaDestinationWithFingerprint:fingerprint];
        } else {
            [[MEGAStore shareInstance] insertOrUpdateMediaDestinationWithFingerprint:fingerprint destination:[NSNumber numberWithLongLong:self.player.currentTime.value] timescale:[NSNumber numberWithInt:self.player.currentTime.timescale]];
        }
    }
}

#pragma mark - Private

- (void)seekToDestination:(MOMediaDestination *)mediaDestination play:(BOOL)play {
    if (!self.fileUrl) {
        return;
    }
    
    self.player = [AVPlayer playerWithURL:self.fileUrl];
    self.delegate = self;
    
    if (mediaDestination) {
        CMTime time = CMTimeMake(mediaDestination.destination.longLongValue, mediaDestination.timescale.intValue);
        if (CMTIME_IS_VALID(time)) {
            [self.player seekToTime:time];
        }
    }
    
    if (play) {
        [self.player play];
    }
}

- (void)replayVideo {
    if (self.player) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
        self.endPlaying = NO;
    }
}

- (void)stopStreaming {
    if (self.node) {
        [self.apiForStreaming httpServerStop];
    }
}

- (NSString *)timeForMediaDestination:(MOMediaDestination *)mediaDestination {
    CMTime mediaTime = CMTimeMake(mediaDestination.destination.longLongValue, mediaDestination.timescale.intValue);
    NSTimeInterval durationSeconds = (NSTimeInterval)CMTimeGetSeconds(mediaTime);
    return [NSString mnz_stringFromTimeInterval:durationSeconds];
}

- (NSString *)fileName {
    if (self.node) {
        return self.node.name;
    } else {
        return self.fileUrl.lastPathComponent;
    }
}

- (NSString *)fileFingerprint {
    NSString *fingerprint;

    if (self.node) {
        fingerprint = self.node.fingerprint;
    } else {
        fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:self.fileUrl.path];
    }
    
    return fingerprint;
}

#pragma mark - Notifications

- (void)movieFinishedCallback:(NSNotification*)aNotification {
    self.endPlaying = YES;
    [self replayVideo];
}

- (void)applicationDidEnterBackground:(NSNotification*)aNotification {
    if (![NSStringFromClass([UIApplication sharedApplication].windows.firstObject.class) isEqualToString:@"UIWindow"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"presentPasscodeLater"];
    }
}

- (void)checkNetworkChanges {
    if (!self.apiForStreaming || !MEGAReachabilityManager.isReachable) {
        return;
    }

    NSURL *oldFileURL = self.fileUrl;
    self.fileUrl = [[MEGASdkManager sharedMEGASdk] httpServerIsLocalOnly] ? [self.apiForStreaming httpServerGetLocalLink:self.node] : [[self.apiForStreaming httpServerGetLocalLink:self.node] mnz_updatedURLWithCurrentAddress];
    if (![oldFileURL isEqual:self.fileUrl]) {
        CMTime currentTime = self.player.currentTime;
        AVPlayerItem *newPlayerItem = [AVPlayerItem playerItemWithURL:self.fileUrl];
        [self.player replaceCurrentItemWithPlayerItem:newPlayerItem];
        if (CMTIME_IS_VALID(currentTime)) {
            [self.player seekToTime:currentTime];
        }
    }
}

#pragma mark - AVPlayerViewControllerDelegate

- (BOOL)playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart:(AVPlayerViewController *)playerViewController {
    return NO;
}

@end
