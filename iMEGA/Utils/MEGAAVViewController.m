#import "MEGAAVViewController.h"

#import <MediaPlayer/MediaPlayer.h>

#import "MEGAQLPreviewControllerTransitionAnimator.h"
#import "Helper.h"

@interface MEGAAVViewController () <UIViewControllerTransitioningDelegate>

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
    [self setTransitioningDelegate:self];
    [self play];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)play {
    if (_path) {
        MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:_path];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(movieFinishedCallback:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:moviePlayerViewController.moviePlayer];
        
        [[NSNotificationCenter defaultCenter] removeObserver:moviePlayerViewController name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        if (_node && ![_node hasThumbnail] && ![self isFolderLink] && isVideo(_node.name.pathExtension)) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleThumbnailImageRequestFinishNotification:)
                                                         name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                                       object:moviePlayerViewController.moviePlayer];
            
            [[moviePlayerViewController moviePlayer] requestThumbnailImagesAtTimes:@[[NSNumber numberWithFloat:0.0]] timeOption:MPMovieTimeOptionExact];
        }

        [self.view addSubview:moviePlayerViewController.view];
        [self addChildViewController:moviePlayerViewController];
        [moviePlayerViewController didMoveToParentViewController:self];
        
        [moviePlayerViewController.moviePlayer prepareToPlay];
        [moviePlayerViewController.moviePlayer play];
    }
}


#pragma mark - Movie player

- (void)movieFinishedCallback:(NSNotification*)aNotification {
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

- (void)handleThumbnailImageRequestFinishNotification:(NSNotification *)aNotification {
    MPMoviePlayerController *moviePlayer = [aNotification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                                  object:moviePlayer];
    UIImage *image = [moviePlayer thumbnailImageAtTime:0.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
    
    NSString *tmpImagePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:_node.base64Handle] stringByAppendingPathExtension:@"jpg"];
    
    [UIImageJPEGRepresentation(image, 1) writeToFile:tmpImagePath atomically:YES];
    
    NSString *thumbnailFilePath = [Helper pathForNode:_node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
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
