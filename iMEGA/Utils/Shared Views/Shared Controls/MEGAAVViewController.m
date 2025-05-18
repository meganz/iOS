#import "MEGAAVViewController.h"

#import "LTHPasscodeViewController.h"

#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

static const NSUInteger MIN_SECOND = 10; // Save only where the users were playing the file, if the streaming second is greater than this value.

@interface MEGAAVViewController () <AVPlayerViewControllerDelegate>

@property (nonatomic, assign, getter=isViewDidAppearFirstTime) BOOL viewDidAppearFirstTime;
@property (nonatomic, strong) NSMutableSet *subscriptions;

@end

@implementation MEGAAVViewController

- (instancetype)initWithURL:(NSURL *)fileUrl {
    self = [super init];
    
    if (self) {
        self.viewModel = [self makeViewModel];
        MEGALogInfo(@"[MEGAAVViewController] init with url: %@", fileUrl);
        self.fileUrl    = fileUrl;
        self.node       = nil;
        _isFolderLink   = NO;
        _subscriptions = [[NSMutableSet alloc] init];
        _hasPlayedOnceBefore = NO;
    }
    
    return self;
}

- (instancetype)initWithNode:(MEGANode *)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk *)apiForStreaming {
    self = [super init];
    
    if (self) {
        self.viewModel = [self makeViewModel];
        _apiForStreaming = apiForStreaming;
        self.node            = folderLink ? [MEGASdk.sharedFolderLink authorizeNode:node] : node;
        _isFolderLink        = folderLink;
        self.fileUrl         = [self streamingPathWithNode:node];
        MEGALogInfo(@"[MEGAAVViewController] init with node %@, is folderLink: %d, fileUrl: %@, apiForStreaming: %@", self.node, folderLink, self.fileUrl, apiForStreaming);
        _hasPlayedOnceBefore = NO;
        
        _playerQueue = dispatch_queue_create("mega.ios.player.queue", NULL);
    }
        
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel onViewDidLoad];
    [self checkIsFileViolatesTermsOfService];
    [AudioSessionUseCaseOCWrapper.alloc.init configureVideoAudioSession];
    
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared audioInterruptionDidStart];
    }

    self.viewDidAppearFirstTime = YES;
    
    self.subscriptions = [self bindToSubscriptionsWithMovieStalled:^{
        [self movieStalledCallback];
    }];
    
    [self configureActivityIndicator];
    
    [self configureViewColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSString *fingerprint = [self fileFingerprint];

    if (self.isViewDidAppearFirstTime) {
        if (fingerprint && ![fingerprint isEqualToString:@""]) {
            MOMediaDestination *mediaDestination;
            if (self.node) {
                mediaDestination = [[MEGAStore shareInstance] fetchRecentlyOpenedNodeWithFingerprint:fingerprint].mediaDestination;
            } else {
                mediaDestination = [[MEGAStore shareInstance] fetchMediaDestinationWithFingerprint:fingerprint];
            }
            if (mediaDestination.destination.longLongValue > 0 && mediaDestination.timescale.intValue > 0) {
                if ([FileExtensionGroupOCWrapper verifyIsVideo:[self fileName]]) {
                    NSString *infoVideoDestination = LocalizedString(@"video.alert.resumeVideo.message", @"Message to show the user info (video name and time) about the resume of the video");
                    infoVideoDestination = [infoVideoDestination stringByReplacingOccurrencesOfString:@"%1$s" withString:[self fileName]];
                    infoVideoDestination = [infoVideoDestination stringByReplacingOccurrencesOfString:@"%2$s" withString:[self timeForMediaDestination:mediaDestination]];
                    UIAlertController *resumeOrRestartAlert = [UIAlertController alertControllerWithTitle:LocalizedString(@"video.alert.resumeVideo.title", @"Alert title shown for video with options to resume playing the video or start from the beginning") message:infoVideoDestination preferredStyle:UIAlertControllerStyleAlert];
                    [resumeOrRestartAlert addAction:[UIAlertAction actionWithTitle:LocalizedString(@"video.alert.resumeVideo.button.restart", @"Alert button title that will start playing the video from the beginning") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self seekToDestination:nil play:YES];
                    }]];
                    [resumeOrRestartAlert addAction:[UIAlertAction actionWithTitle:LocalizedString(@"video.alert.resumeVideo.button.resume", @"Alert button title that will resume playing the video") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self seekToDestination:mediaDestination play:YES];
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
    
    [[AVPlayerManager shared] assignDelegateTo:self];
    
    self.viewDidAppearFirstTime = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if ([[AVPlayerManager shared] isPIPModeActiveFor:self]) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self stopStreaming];

        if (![AudioPlayerManager.shared isPlayerAlive]) {
            [AudioSessionUseCaseOCWrapper.alloc.init configureDefaultAudioSession];
        }

        if ([AudioPlayerManager.shared isPlayerAlive]) {
            [AudioPlayerManager.shared audioInterruptionDidEndNeedToResume:YES];
        }
    });
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"presentPasscodeLater"] && [LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenOver:UIApplication.mnz_presentingViewController.view
                                                     withAnimation:YES
                                                        withLogout:YES
                                                    andLogoutTitle:LocalizedString(@"logoutLabel", @"")];
    }
    
    [self deallocPlayer];
    [self cancelPlayerProcess];
    self.player = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([[AVPlayerManager shared] isPIPModeActiveFor:self]) {
        return;
    }

    CMTime mediaTime = CMTimeMake(self.player.currentTime.value, self.player.currentTime.timescale);
    Float64 second = CMTimeGetSeconds(mediaTime);
    
    NSString *fingerprint = [self fileFingerprint];
    
    if (fingerprint && ![fingerprint isEqualToString:@""]) {
        if (self.isEndPlaying || second <= MIN_SECOND) {
            [[MEGAStore shareInstance] deleteMediaDestinationWithFingerprint:fingerprint];
            [self saveRecentlyWatchedVideoWithDestination:[NSNumber numberWithInt:0]
                                                timescale:nil];
        } else {
            if (self.node) {
                [self saveRecentlyWatchedVideoWithDestination:[NSNumber numberWithLongLong:self.player.currentTime.value]
                                                    timescale:[NSNumber numberWithInt:self.player.currentTime.timescale]];
            } else {
                [[MEGAStore shareInstance] insertOrUpdateMediaDestinationWithFingerprint:fingerprint destination:[NSNumber numberWithLongLong:self.player.currentTime.value] timescale:[NSNumber numberWithInt:self.player.currentTime.timescale]];
            }
        }
    }
}

#pragma mark - Private

/**
 从trace和图中可以看出，Hang的原因就是调用`seekToDestination`方法，从代码中很容易看出，这个方法是通过url加载音频或者视频，`seekToDestination`的下一个调用栈为 `[AVPlayerViewController setPlayer]`
 
 ### Hang分析
 ```Objective-C
 AVAsset *asset = [AVAsset assetWithURL:self.fileUrl];
 AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
 ```
 这两行本身都是同步的，但是`fileUrl`如果指向的是一个很大的本地资源或者远程资源，就会导致这个同步方法阻塞线程，从堆栈信息看`seekToDestination` 是在 `viewDidAppear`之后调用的，没有特殊指定线程，则默认会在主线程调用，就会导致阻塞主线程，从而被系统判定为Hang
 
 ### 解决方案
 1. 把`seekToDestination`给放到后台线程去执行，只在关键的调用转回主线程
 2. 使用 `AVURLAsset` 的异步加载，并通过 `status` 来判断是否能够播放
 
 */

- (void)seekToDestination:(MOMediaDestination *)mediaDestination play:(BOOL)play {
    if (!self.fileUrl) {
        return;
    }
    
    [self willStartPlayer];
    
    dispatch_async(_playerQueue, ^{
        AVURLAsset *asset = [AVURLAsset assetWithURL:self.fileUrl];
        [asset loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:^{
            
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:@"playable" error:&error];
            
            switch (status) {
                case AVKeyValueStatusLoaded: {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
                        [self setPlayerItemMetadataWithPlayerItem:playerItem node:self.node];
                        self.player = [AVPlayer playerWithPlayerItem:playerItem];
                        [self.subscriptions addObject:[self bindPlayerItemStatusWithPlayerItem:playerItem]];
                        
                        [self seekToMediaDestination:mediaDestination];
                        
                        if (play) {
                            [self.player play];
                        }
                        
                        [self.subscriptions addObject:[self bindPlayerTimeControlStatus]];

                    });
                    break;

                }
                case AVKeyValueStatusFailed:
                case AVKeyValueStatusCancelled:
                    // 这里处理无法播放的情况
                    break;
                default:
                    break;
            }
            
        }];
    });
}

- (void)replayVideo {
    if (self.player) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
        self.isEndPlaying = NO;
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
        MEGALogInfo(@"[MEGAAVViewController] Getting fileFingerprint from node %@", self.node);
        fingerprint = self.node.fingerprint;
    } else {
        fingerprint = [MEGASdk.shared fingerprintForFilePath:self.fileUrl.path];
        MEGALogInfo(@"[MEGAAVViewController] Getting fileFingerprint from sdk with result %@", fingerprint);
    }
    
    return fingerprint;
}

@end
