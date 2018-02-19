#import "OpenInActivity.h"
#import "Helper.h"

@interface OpenInActivity () <UIDocumentInteractionControllerDelegate>

@property (strong, nonatomic) UIBarButtonItem *shareBarButtonItem;
@property (strong, nonatomic) UIView *view;
@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;

@end

@implementation OpenInActivity

- (instancetype)initOnBarButtonItem:(UIBarButtonItem *)barButtonItem {
    self = [super init];
    if (self) {
        _shareBarButtonItem = barButtonItem;
    }
    return self;
}

- (instancetype)initOnView:(UIView *)view {
    self = [super init];
    if (self) {
        _view = view;
    }
    return self;
}

- (NSString *)activityType {
    return @"OpenInActivity";
}

- (NSString *)activityTitle {
    return AMLocalizedString(@"openIn", @"Title shown under the action that allows you to open a file in another app");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_openIn"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[activityItems objectAtIndex:0]];
    [self.documentInteractionController setDelegate:self];
}

- (void)performActivity {
    BOOL canOpenIn;
    if (self.shareBarButtonItem) {
        canOpenIn = [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.shareBarButtonItem animated:YES];
    } else {
        canOpenIn = [self.documentInteractionController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
    }
    if (canOpenIn) {
        [self.documentInteractionController presentPreviewAnimated:YES];
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
