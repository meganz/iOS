#import "MEGAQLPreviewController.h"
#import "MEGALinkManager.h"
#import "MEGA-Swift.h"

@interface MEGAQLPreviewController () <UIViewControllerTransitioningDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource>

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSArray *files;

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = UIColor.pageBackgroundColor;
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
    dispatch_async(dispatch_get_main_queue(), ^{
        MEGALinkManager.linkURL = url;
        [MEGALinkManager processLinkURL:url];
    });

    return NO;
}


@end
