#import "MEGAActivityItemProvider.h"

#import "MEGAReachabilityManager.h"

#import "SVProgressHUD.h"

@interface MEGAActivityItemProvider () <UIActivityItemSource, MEGARequestDelegate> {
    dispatch_semaphore_t semaphore;
}

@property (strong, nonatomic) MEGANode *node;

@property (strong, nonatomic) NSString *link;

@end

@implementation MEGAActivityItemProvider

- (instancetype)initWithPlaceholderString:(NSString*)placeholder node:(MEGANode *)node {
    self = [super initWithPlaceholderItem:placeholder];
    if (self) {
        _node = node;
        _link = @"";
    }
    return self;
}

- (id)item {
    
    NSString *activityType = [self activityType];
    BOOL activityValue = !([activityType isEqualToString:@"OpenInActivity"] || [activityType isEqualToString:@"GetLinkActivity"] || [activityType isEqualToString:@"RemoveLinkActivity"] || [activityType isEqualToString:@"ShareFolderActivity"] || [activityType isEqualToString:@"SaveToCameraRollActivity"]);
    if (activityValue) {
        semaphore = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                [[MEGASdkManager sharedMEGASdk] exportNode:_node delegate:self];
            }
            
        });
        
        double delayInSeconds = 10.0;
        dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_semaphore_wait(semaphore, waitTime);
    }
    
    return _link;
}

#pragma mark - UIActivityItemSource

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    if ([activityType isEqualToString:UIActivityTypeAirDrop]) {
        return [NSURL URLWithString:self.link];
    }
    
    if ([activityType isEqualToString:@"OpenInActivity"] || [activityType isEqualToString:@"GetLinkActivity"] || [activityType isEqualToString:@"RemoveLinkActivity"] || [activityType isEqualToString:@"ShareFolderActivity"] || [activityType isEqualToString:@"SaveToCameraRollActivity"]) {

        return nil;
    }
    
    return _link;
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size {
    return [UIImage imageNamed:@"AppIcon"];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeExport: {
            if ([request access]) {
                _link = [request link];
                
                dispatch_semaphore_signal(semaphore);
            }
            break;
        }
            
        default:
            break;
    }
}

@end
