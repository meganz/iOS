/**
 * @file MainTabBarController.h
 * @brief Main tab bar of the app
 *
 * (c) 2013-2014 by Mega Limited, Auckland, New Zealand
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

@interface MainTabBarController () 

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *viewControllerArray = [[NSMutableArray alloc] initWithCapacity:5];

    [viewControllerArray addObject:[[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateInitialViewController]];
    [viewControllerArray addObject:[[UIStoryboard storyboardWithName:@"Photos" bundle:nil] instantiateInitialViewController]];
    [viewControllerArray addObject:[[UIStoryboard storyboardWithName:@"Offline" bundle:nil] instantiateInitialViewController]];
    [viewControllerArray addObject:[[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateInitialViewController]];
    [viewControllerArray addObject:[[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateInitialViewController]];

    [self setViewControllers:viewControllerArray];
    
    UIImage *tabHighlightImage = [[UIImage imageNamed:@"tabHighlight"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    CGSize tabSize = CGSizeMake(self.view.frame.size.width/[self.tabBar.items count], self.tabBar.frame.size.height);
    
    UIGraphicsBeginImageContext(tabSize);
    [tabHighlightImage drawInRect:CGRectMake(0, 0, tabSize.width, tabSize.height)];
    UIImage *resizedHighlightImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.tabBar setSelectionIndicatorImage:resizedHighlightImage];
}

@end
