/**
 * @file OpenInActivity.m
 * @brief UIActivity for opening files in other apps
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

#import "OpenInActivity.h"
#import "Helper.h"

@interface OpenInActivity () <UIDocumentInteractionControllerDelegate>

@property (strong, nonatomic) UIBarButtonItem *shareBarButtonItem;
@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;

@end

@implementation OpenInActivity

- (instancetype)initOnBarButtonItem:(UIBarButtonItem *)barButtonItem {
    _shareBarButtonItem = barButtonItem;
    
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

    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)) {
        self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[activityItems objectAtIndex:0]];
        [self.documentInteractionController setDelegate:self];
    }
}

- (void)performActivity {
    
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)) {
        BOOL canOpenIn = [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.shareBarButtonItem animated:YES];
        if (canOpenIn) {
            [self.documentInteractionController presentPreviewAnimated:YES];
        }
    } else {
        [self activityDidFinish:YES];
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
