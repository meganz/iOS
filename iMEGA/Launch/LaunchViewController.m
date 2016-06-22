/**
 * @file LaunchViewController.m
 * @brief View controller to facilitate the transition between views on the app.
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

#import <sys/utsname.h>

#import "Helper.h"

#import "LaunchViewController.h"

@interface LaunchViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressViewHeightLayoutConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressViewLeadingLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressViewTrailingMarginLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressViewBottomLayoutConstraint;

@end

@implementation LaunchViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *versionNumber = @"";
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        versionNumber = [modelName substringFromIndex:5]; //"iPadX,X"
        if ([versionNumber isEqualToString:@"1,1"]) {
            [_progressViewHeightLayoutConstraint setConstant:2.0f];
            
            [_progressViewLeadingLayoutConstraint setConstant:72.0f];
            [_progressViewTrailingMarginLayoutConstraint setConstant:72.0f];
            [_progressViewBottomLayoutConstraint setConstant:111.0f];
        } else {
            [_progressViewHeightLayoutConstraint setConstant:4.0f];
            
            [_progressViewLeadingLayoutConstraint setConstant:145.0f];
            [_progressViewTrailingMarginLayoutConstraint setConstant:145.0f];
            [_progressViewBottomLayoutConstraint setConstant:221.0f];
        }
    } else {
        [_progressViewHeightLayoutConstraint setConstant:4.0f];
        
        if ([[UIDevice currentDevice] iPhone4X]) {
            [_progressViewLeadingLayoutConstraint setConstant:40.0f];
            [_progressViewTrailingMarginLayoutConstraint setConstant:40.0f];
            [_progressViewBottomLayoutConstraint setConstant:85.0f];
        } else if ([[UIDevice currentDevice] iPhone5X]) {
            [_progressViewLeadingLayoutConstraint setConstant:40.0f];
            [_progressViewTrailingMarginLayoutConstraint setConstant:40.0f];
            [_progressViewBottomLayoutConstraint setConstant:107.0f];
        } else if ([[UIDevice currentDevice] iPhone6X]) {
            [_progressViewLeadingLayoutConstraint setConstant:67.5f];
            [_progressViewTrailingMarginLayoutConstraint setConstant:67.5f];
            [_progressViewBottomLayoutConstraint setConstant:125.0f];
        } else if ([[UIDevice currentDevice] iPhone6XPlus]) {
            [_progressViewLeadingLayoutConstraint setConstant:52.0f];
            [_progressViewTrailingMarginLayoutConstraint setConstant:52.0f];
            [_progressViewBottomLayoutConstraint setConstant:138.0f];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end

