
#import "MEGAAVViewController.h"

#import "Helper.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"
#import "MEGANode+MNZCategory.h"
#import "NSString+MNZCategory.h"

@interface MEGAAVViewController () <UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, nonnull) NSURL *path;
@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, assign, getter=isFolderLink) BOOL folderLink;

@property (nonatomic) AVPlayerViewController *moviePlayerViewController;

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
    
    [self.moviePlayerViewController.player play];
}

- (void)play {
    if (self.path) {
        self.moviePlayerViewController = [AVPlayerViewController new];
        self.moviePlayerViewController.player = [AVPlayer playerWithURL:self.path];
        
        [self addChildViewController:self.moviePlayerViewController];
        CGFloat y = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
        self.moviePlayerViewController.view.frame = CGRectMake(0.0f, y, self.view.frame.size.width, self.view.frame.size.height - y);
        [self.view addSubview:self.moviePlayerViewController.view];
        
        if (self.node && !self.node.hasThumbnail && !self.isFolderLink && self.node.name.mnz_isVideoPathExtension) {
            [self.node mnz_generateThumbnailForVideoAtPath:self.path];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(movieFinishedCallback:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:self.moviePlayerViewController.player.currentItem];
    }
}

#pragma mark - Notifications

- (void)movieFinishedCallback:(NSNotification*)aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.moviePlayerViewController.player.currentItem];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (self.node) {
        if (![self isFolderLink]) {
            [[MEGASdkManager sharedMEGASdk] httpServerStop];
        } else {
            [[MEGASdkManager sharedMEGASdkFolder] httpServerStop];
        }
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    if ([presented isKindOfClass:[AVPlayerViewController class]]) {
        return [[MEGAQLPreviewControllerTransitionAnimator alloc] init];
    }
    return nil;
}

@end
