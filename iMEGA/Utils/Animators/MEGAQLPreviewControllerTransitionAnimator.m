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
