#import "MEGAAVViewController.h"

#import <MediaPlayer/MediaPlayer.h>

#import "Helper.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"
#import "NSString+MNZCategory.h"

@interface MEGAAVViewController () <UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, nonnull) NSURL *path;
@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, assign, getter=isFolderLink) BOOL folderLink;

@property (nonatomic) MPMoviePlayerViewController *moviePlayerViewController;

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
    [self setTransitioningDelegate:self];
    [self play];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.moviePlayerViewController.moviePlayer prepareToPlay];
    [self.moviePlayerViewController.moviePlayer play];
}

- (void)play {
    if (_path) {
        if (self.moviePlayerViewController) {
            [self.moviePlayerViewController.view removeFromSuperview];
            self.moviePlayerViewController = nil;
        }
        
        self.moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:_path];
        self.moviePlayerViewController.moviePlayer.movieSourceType = (self.node) ? MPMovieSourceTypeStreaming : MPMovieSourceTypeFile;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(movieFinishedCallback:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:self.moviePlayerViewController.moviePlayer];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayerViewController name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        if (self.node && !self.node.hasThumbnail && !self.isFolderLink && self.node.name.mnz_isVideoPathExtension) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleThumbnailImageRequestFinishNotification:)
                                                         name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                                       object:self.moviePlayerViewController.moviePlayer];
            
            [[self.moviePlayerViewController moviePlayer] requestThumbnailImagesAtTimes:@[[NSNumber numberWithFloat:0.0]] timeOption:MPMovieTimeOptionExact];
        }
    
        [self.view addSubview:self.moviePlayerViewController.view];
        [self addChildViewController:self.moviePlayerViewController];
        [self.moviePlayerViewController didMoveToParentViewController:self];
        
        [self.moviePlayerViewController.moviePlayer setShouldAutoplay:NO];
    }
}

#pragma mark - Movie player

- (void)movieFinishedCallback:(NSNotification*)aNotification {
    NSInteger reason = ((NSNumber *)[aNotification.userInfo objectForKey:@"MPMoviePlayerPlaybackDidFinishReasonUserInfoKey"]).integerValue;
    if (!self.peekAndPop || reason!=MPMovieFinishReasonPlaybackEnded) {
        MPMoviePlayerController *moviePlayer = [aNotification object];
        [moviePlayer cancelAllThumbnailImageRequests];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                      object:moviePlayer];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        if (_node) {
            if (![self isFolderLink]) {
                [[MEGASdkManager sharedMEGASdk] httpServerStop];
            } else {
                [[MEGASdkManager sharedMEGASdkFolder] httpServerStop];
            }
        }
    }
}

- (void)handleThumbnailImageRequestFinishNotification:(NSNotification *)aNotification {
    MPMoviePlayerController *moviePlayer = [aNotification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                                  object:moviePlayer];
    UIImage *image = [moviePlayer thumbnailImageAtTime:0.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
    
    NSString *tmpImagePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:_node.base64Handle] stringByAppendingPathExtension:@"jpg"];
    
    [UIImageJPEGRepresentation(image, 1) writeToFile:tmpImagePath atomically:YES];
    
    NSString *thumbnailFilePath = [Helper pathForNode:_node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
    [[MEGASdkManager sharedMEGASdk] createThumbnail:tmpImagePath destinatioPath:thumbnailFilePath];
    [[MEGASdkManager sharedMEGASdk] setThumbnailNode:_node sourceFilePath:thumbnailFilePath];
    
    NSString *previewFilePath = [Helper pathForNode:_node searchPath:NSCachesDirectory directory:@"previewsV3"];
    [[MEGASdkManager sharedMEGASdk] createPreview:tmpImagePath destinatioPath:previewFilePath];
    [[MEGASdkManager sharedMEGASdk] setPreviewNode:_node sourceFilePath:previewFilePath];
    
    [[NSFileManager defaultManager] removeItemAtPath:tmpImagePath error:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    if ([presented isKindOfClass:[MPMoviePlayerViewController class]]) {
        return [[MEGAQLPreviewControllerTransitionAnimator alloc] init];
    }
    return nil;
}

@end
