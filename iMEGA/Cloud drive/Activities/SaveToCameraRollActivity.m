
#import "SaveToCameraRollActivity.h"

#import "MEGANode+MNZCategory.h"

@interface SaveToCameraRollActivity ()

@property (nonatomic, strong) MEGANode *node;
@property (nonatomic) MEGASdk *api;

@end

@implementation SaveToCameraRollActivity


- (instancetype)initWithNode:(MEGANode *)node api:(MEGASdk *)api {
    self = [super init];
    if (self) {
        _node = node;
        _api = api;
    }
    return self;
}

- (NSString *)activityType {
    return MEGAUIActivityTypeSaveToCameraRoll;
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"saveImage", nil);
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_saveImage"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)performActivity {
    [self.node mnz_saveToPhotos];
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
