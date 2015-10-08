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

@interface OpenInActivity () <UIDocumentInteractionControllerDelegate> {
    UIDocumentInteractionController *documentInteractionController;
    UIBarButtonItem *openInBarButtonItem;
}

@end

@implementation OpenInActivity

- (id)initOnBarButtonItem:(UIBarButtonItem *)barButtonItem {
    openInBarButtonItem = barButtonItem;
    
    documentInteractionController = [[UIDocumentInteractionController alloc] init];
    [documentInteractionController setDelegate:self];
    
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
    [documentInteractionController setURL:[activityItems objectAtIndex:0]];
}

- (void)performActivity {
    
    BOOL canOpenIn = [documentInteractionController presentOpenInMenuFromBarButtonItem:openInBarButtonItem animated:YES];
    
    if (canOpenIn) {
        [documentInteractionController presentPreviewAnimated:YES];
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
