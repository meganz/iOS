/**
 * @file MainTabBarController.h
 * @brief Main tab bar of the app
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

#import "MainTabBarController.h"
#import "Helper.h"

@interface MainTabBarController () <UITabBarControllerDelegate>

@end

@implementation MainTabBarController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *defaultViewControllersMutableArray = [[NSMutableArray alloc] initWithCapacity:6];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Photos" bundle:nil] instantiateInitialViewController]];
    [[[defaultViewControllersMutableArray objectAtIndex:1] tabBarItem] setTitle:@"Camera Uploads"];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Offline" bundle:nil] instantiateInitialViewController]];
    [[[defaultViewControllersMutableArray objectAtIndex:2] tabBarItem] setTitle:@"Offline"];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateInitialViewController]];
    [[[defaultViewControllersMutableArray objectAtIndex:3] tabBarItem] setTitle:AMLocalizedString(@"contactsTitle", @"Contacts")];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Transfers" bundle:nil] instantiateInitialViewController]];
    [[[defaultViewControllersMutableArray objectAtIndex:4] tabBarItem] setTitle:AMLocalizedString(@"transfers", @"Transfers")];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateInitialViewController]];
    [[[defaultViewControllersMutableArray objectAtIndex:5] tabBarItem] setTitle:AMLocalizedString(@"settingsTitle", @"Settings")];
    
    for (NSInteger i = 0; i< [defaultViewControllersMutableArray count]; i++) {
        UITabBarItem *tabBarItem = [[defaultViewControllersMutableArray objectAtIndex:i] tabBarItem];
        switch (tabBarItem.tag) {
            case 0:
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"cloudDriveSelectedIcon"]];
                break;
                
            case 1:
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"cameraUploadsSelectedIcon"]];
                break;
                
            case 2:
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"offlineSelectedIcon"]];
                break;
                
            case 3:
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"contactsSelectedIcon"]];
                break;
                
            case 4:
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"transfersSelectedIcon"]];
                break;
                
            case 5:
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"settingsSelectedIcon"]];
                break;
        }
    }
    
    [self.view setTintColor:megaRed];
    [self.moreNavigationController.view setTintColor:megaRed];
    
    NSArray *tabsOrderArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"TabsOrderInTabBar"];
    if (tabsOrderArray) {
        NSMutableArray *customOrderMutableArray = [NSMutableArray arrayWithCapacity:defaultViewControllersMutableArray.count];
        for (NSNumber *tabBarNumber in tabsOrderArray) {
            [customOrderMutableArray addObject:[defaultViewControllersMutableArray objectAtIndex:tabBarNumber.unsignedIntegerValue]];
        }
        [self setViewControllers:customOrderMutableArray];
    } else {
        [self setViewControllers:defaultViewControllersMutableArray];
    }
    
    [self setDelegate:self];
    
}

- (BOOL)shouldAutorotate {
    if ([self.selectedViewController respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.selectedViewController shouldAutorotate];
    } else {
        return YES;
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([self.selectedViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        if ([self.selectedViewController isEqual:self.moreNavigationController]) {
            return UIInterfaceOrientationMaskPortrait;
        }
        return [self.selectedViewController supportedInterfaceOrientations];
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if ([self.selectedViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        if ([self.selectedViewController isEqual:self.moreNavigationController]) {
            return UIInterfaceOrientationPortrait;
        }
        return [self.selectedViewController preferredInterfaceOrientationForPresentation];
    }
    return UIInterfaceOrientationPortrait;
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
    if (changed) {
        NSMutableArray *tabsOrderMutableArray = [[NSMutableArray alloc] initWithCapacity:viewControllers.count];
        for (UINavigationController *navigationController in viewControllers) {
            [tabsOrderMutableArray addObject:[NSNumber numberWithInteger:navigationController.tabBarItem.tag]];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:tabsOrderMutableArray] forKey:@"TabsOrderInTabBar"];
    }
}

@end
