#import "MEGAActivityItemProvider.h"

#import <LinkPresentation/LinkPresentation.h>

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

#import "Helper.h"
#import "UIImageView+MNZCategory.h"

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
    BOOL activityValue = !([activityType isEqualToString:MEGAUIActivityTypeOpenIn] || [activityType isEqualToString:MEGAUIActivityTypeGetLink] || [activityType isEqualToString:MEGAUIActivityTypeRemoveLink] || [activityType isEqualToString:MEGAUIActivityTypeShareFolder] || [activityType isEqualToString:MEGAUIActivityTypeSaveToCameraRoll] || [activityType isEqualToString:MEGAUIActivityTypeRemoveSharing] || [activityType isEqualToString:MEGAUIActivityTypeSendToChat]);
    if (activityValue) {
        if (self.node.isExported) {
            self.link = self.node.publicLink;
        } else {
            semaphore = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (MEGAReachabilityManager.isReachableHUDIfNot) {
                    [MEGASdkManager.sharedMEGASdk exportNode:self.node delegate:self];
                }
            });
            double delayInSeconds = 10.0;
            dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_semaphore_wait(semaphore, waitTime);
        }
    }
    
    return _link;
}

#pragma mark - UIActivityItemSource

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    if ([activityType isEqualToString:UIActivityTypeAirDrop]) {
        return [NSURL URLWithString:self.link];
    }
    
    if ([activityType isEqualToString:MEGAUIActivityTypeOpenIn] || [activityType isEqualToString:MEGAUIActivityTypeGetLink] || [activityType isEqualToString:MEGAUIActivityTypeRemoveLink] || [activityType isEqualToString:MEGAUIActivityTypeShareFolder] || [activityType isEqualToString:MEGAUIActivityTypeSaveToCameraRoll] || [activityType isEqualToString:MEGAUIActivityTypeRemoveSharing]) {

        return nil;
    }
    
    return _link;
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size {
    return [UIImage imageNamed:@"AppIcon"];
}

- (LPLinkMetadata *)activityViewControllerLinkMetadata:(UIActivityViewController *)activityViewController  API_AVAILABLE(ios(13.0)) {
    LPLinkMetadata *metadata = LPLinkMetadata.new;
    metadata.title = self.node.name;

    NSString *subtitleString;
    if (self.node.isFile) {
        subtitleString = [Helper sizeAndModicationDateForNode:self.node api:MEGASdkManager.sharedMEGASdk];
    } else if (self.node.isFolder) {
        subtitleString = [Helper filesAndFoldersInFolderNode:self.node api:MEGASdkManager.sharedMEGASdk];
    }
    metadata.originalURL = [NSURL.alloc initFileURLWithPath:subtitleString];

    if (self.node.hasThumbnail) {
        NSString *thumbnailFilePath = [Helper pathForNode:self.node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
        if ([NSFileManager.defaultManager fileExistsAtPath:thumbnailFilePath]) {
            NSItemProvider *iconItemProvider = [NSItemProvider.new initWithObject:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
            metadata.iconProvider = iconItemProvider;
        }
    } else {
        UIImageView *imageView = UIImageView.new;
        [imageView mnz_imageForNode:self.node];
        NSItemProvider *iconItemProvider = [NSItemProvider.new initWithObject:imageView.image];
        metadata.iconProvider = iconItemProvider;
    }

    return metadata;
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
