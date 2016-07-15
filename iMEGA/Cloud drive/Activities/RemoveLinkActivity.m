/**
 * @file RemoveLinkActivity.m
 * @brief UIActivity for removing a public link
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

#import "RemoveLinkActivity.h"

#import "MEGAReachabilityManager.h"

#import "SVProgressHUD.h"

@interface RemoveLinkActivity ()

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) NSArray *nodes;

@end

@implementation RemoveLinkActivity

- (instancetype)initWithNode:(MEGANode *)nodeCopy {
    _node = nodeCopy;
    
    return self;
}

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    _nodes = nodesArray;
    
    return self;
}

- (NSString *)activityType {
    return @"RemoveLinkActivity";
}

- (NSString *)activityTitle {
    if ([self.nodes count] > 1) {
        return AMLocalizedString(@"removeLinks", nil);
    }
    
    return AMLocalizedString(@"removeLink", nil);
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_removeLink"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    
}

- (void)performActivity {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (self.nodes != nil) {
            for (MEGANode *n in self.nodes) {
                [[MEGASdkManager sharedMEGASdk] disableExportNode:n];
            }
        } else {
            [[MEGASdkManager sharedMEGASdk] disableExportNode:self.node];
        }
        
        if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedDescending)) {
            [self activityDidFinish:YES];
        }
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
