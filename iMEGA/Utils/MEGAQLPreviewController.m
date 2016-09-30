
#import "MEGAQLPreviewController.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"

@interface MEGAQLPreviewController () <UIViewControllerTransitioningDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource>

@property (nonatomic, strong, nonnull) NSString *filePath;
@property (nonatomic, strong, nonnull) NSArray *files;

@end

@implementation MEGAQLPreviewController

- (instancetype)initWithFilePath:(NSString *)filePath {    
    self = [super init];
    
    if (self) {
        _filePath                  = filePath;
        _files                     = nil;
        self.delegate              = self;
        self.dataSource            = self;
        self.title                 = [filePath lastPathComponent];
        self.transitioningDelegate = self;
    }
    
    return self;
}

- (instancetype)initWithArrayOfFiles:(NSArray *)files {
    self = [super init];
    
    if (self) {
        _files                     = files;
        _filePath                  = nil;
        self.delegate              = self;
        self.dataSource            = self;
        self.transitioningDelegate = self;
    }
    
    return self;
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    if (self.files) {
        return self.files.count;
    } else {
        return 1;
    }
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    if (self.files) {
        self.filePath = [self.files objectAtIndex:index];
    }
    return [NSURL fileURLWithPath:self.filePath];
}

#pragma mark - QLPreviewControllerDelegate

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    if ([presented isKindOfClass:[QLPreviewController class]]) {
        return [[MEGAQLPreviewControllerTransitionAnimator alloc] init];
    }
    
    return nil;
}

@end
