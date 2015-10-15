/**
 * @file MEGAActivityItemProvider.m
 * @brief UIActivityItemProvider
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "MEGAActivityItemProvider.h"

#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"

@interface MEGAActivityItemProvider () <UIActivityItemSource, MEGARequestDelegate> {
    dispatch_semaphore_t semaphore;
}

@property (strong, nonatomic) MEGANode *node;

@property (strong, nonatomic) NSString *link;

@end

@implementation MEGAActivityItemProvider

- (id)initWithPlaceholderString:(NSString*)placeholder node:(MEGANode *)node {
    self = [super initWithPlaceholderItem:placeholder];
    if (self) {
        _node = node;
        _link = @"";
    }
    return self;
}

- (id)item {
    
    NSString *activityType = [self activityType];
    BOOL activityValue = !([activityType isEqualToString:@"OpenInActivity"] || [activityType isEqualToString:@"RemoveLinkActivity"] || [activityType isEqualToString:@"ShareFolderActivity"]);
    if (activityValue) {
        semaphore = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([MEGAReachabilityManager isReachable]) {
                [[MEGASdkManager sharedMEGASdk] exportNode:_node delegate:self];
            } else {
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
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
    
    if ([activityType isEqualToString:@"OpenInActivity"] || [activityType isEqualToString:@"RemoveLinkActivity"] || [activityType isEqualToString:@"ShareFolderActivity"]) {
        return nil;
    }
    
    return _link;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeExport: {
            if ([request access]) {
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudLink"] status:AMLocalizedString(@"generatingLink", nil)];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeExport: {
            if ([request access]) {
                [SVProgressHUD dismiss];
                
                _link = [request link];
                
                dispatch_semaphore_signal(semaphore);
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
    
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    
}

@end
