/**
 * @file MEGAQLPreviewControllerTransitionAnimator.m
 * @brief Animation for the transition between view controller and QLPreviewController
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

#import "MEGAQLPreviewControllerTransitionAnimator.h"

@implementation MEGAQLPreviewControllerTransitionAnimator

#pragma mark - UIViewControllerAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)context {
    
    UIViewController *presentedVC = [context viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect bounds = [[[UIApplication sharedApplication] keyWindow] bounds];
    [presentedVC.view setFrame:CGRectMake(bounds.origin.x, bounds.origin.y + bounds.size.height, bounds.size.width, bounds.size.height)];
    
    [[context containerView] addSubview:presentedVC.view];
    
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionTransitionNone animations:^{
        [presentedVC.view setFrame:bounds];
    } completion:^(BOOL transitionFinished) {
        [context completeTransition:transitionFinished];
    }];
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.4;
}

@end
